SYSTEM_PROMPT = <<~PROMPT
  You are an expert film curator and passionate cinephile.

  Rules for responses (VERY IMPORTANT):
  - Keep responses compact so they fit on one screen.
  - Recommend between 4-6 films.
  - Format each film as ONE bullet line ONLY, like:
    • **Title (Year)** — 112 min: short sentence. Second short sentence.
  - Do NOT add blank lines between film bullets.
  - After the last film bullet, add ONE blank line, then:
    Refine:
  - Then EXACTLY 3 bullet lines (no blank lines), each starting with "• ".

  Other rules:
  - Never recommend the same film twice in a conversation.
  - Be confident, warm, and a little obsessive. Zero snobbery.
PROMPT

class MessagesController < ApplicationController
  MIN_FILMS = 4
  MAX_FILMS = 6
  REFINE_BULLETS = 3

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-mini")
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)

      clean = normalize_ai_text(response.content)

      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: clean,
        chat: @chat
      )

      upsert_recommended_films_from(clean)

      @chat.generate_title_from_first_message

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_message_container",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        end
        format.html { render "chats/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :file)
  end

  def watch_session_context
    "Watch session context:\n" \
      "- genre: #{@watch_session.genre}\n" \
      "- mood: #{@watch_session.mood}\n" \
      "- title: #{@watch_session.title}\n" \
      "- description: #{@watch_session.description}"
  end

  def instructions
    [SYSTEM_PROMPT, watch_session_context].compact.join("\n\n")
  end

  def normalize_ai_text(text)
    s = text.to_s.gsub(/\r\n?/, "\n").strip

    s = s.gsub(/^\s{0,3}#{Regexp.escape('#')}{1,6}\s+/, "")
    s = s.gsub(/^\s*[-*]\s+/, "• ")
    s = s.gsub(/\s+•\s+/, "\n• ")
    s = s.gsub(/\s*Refine:\s*/m, "\nRefine:\n")
    s = s.gsub(/[ \t]+\n/, "\n")
    s = s.gsub(/\n{3,}/, "\n\n").strip

    lines = s.split("\n").map(&:rstrip)
    lines.reject! { |l| l.strip.empty? || l.strip == "•" }

    refine_index = lines.index { |l| l.strip.casecmp("Refine:").zero? }
    film_lines = []
    refine_lines = []

    if refine_index
      film_lines = lines[0...refine_index]
      refine_lines = lines[(refine_index + 1)..] || []
    else
      film_lines = lines
      refine_lines = []
    end

    film_lines = film_lines.select { |l| l.strip.start_with?("•") }
    film_lines = film_lines.first(MAX_FILMS)
    film_lines = film_lines.first(MIN_FILMS) if film_lines.length < MIN_FILMS

    refine_lines = refine_lines.select { |l| l.strip.start_with?("•") }
    refine_lines = refine_lines.first(REFINE_BULLETS)

    if refine_lines.length < REFINE_BULLETS
      defaults = [
        "• Want more gore vs. paranormal?",
        "• Pick a runtime cap (e.g., < 100 min).",
        "• Choose era: classics, 2000s, or modern."
      ]
      refine_lines += defaults[(refine_lines.length)...REFINE_BULLETS]
    end

    out = []
    out.concat(film_lines)
    out << ""
    out << "Refine:"
    out.concat(refine_lines)

    out.join("\n").strip
  end

  def upsert_recommended_films_from(clean_text)
    film_lines = clean_text
                 .to_s
                 .gsub(/\r\n?/, "\n")
                 .split("\n")
                 .map(&:strip)

    refine_at = film_lines.index { |l| l.casecmp("Refine:").zero? }
    film_lines = refine_at ? film_lines[0...refine_at] : film_lines
    film_lines = film_lines.select { |l| l.start_with?("•") }

    film_lines.first(MAX_FILMS).each do |line|
      film = parse_film_line(line)
      next if film.nil?
      next if film[:title].blank?

      @chat.recommended_films.find_or_create_by!(
        title: film[:title],
        year: film[:year]
      ) do |rf|
        rf.runtime_minutes = film[:runtime_minutes]
        rf.summary = film[:summary]
      end
    end
  end

  def parse_film_line(line)
    s = line.to_s.strip
    s = s.sub(/\A•\s*/, "")
    s = s.gsub(/\*\*(.*?)\*\*/, '\1').strip

    m = s.match(/\A(?<title>.+?)\s*\((?<year>\d{4})\)\s*—\s*(?<runtime>\d+)\s*min:\s*(?<summary>.+)\z/)
    return nil unless m

    {
      title: m[:title].to_s.strip,
      year: m[:year].to_i,
      runtime_minutes: m[:runtime].to_i,
      summary: m[:summary].to_s.strip
    }
  end
end
