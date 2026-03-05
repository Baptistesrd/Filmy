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
  MAX_FILMS = 6
  REFINE_BULLETS = 3

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session

    @message = @chat.messages.new(message_params)
    @message.role = "user"

    if @message.save
      response_text = call_ruby_llm(@message.content)
      clean = normalize_ai_text(response_text)

      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: clean
      )

      @chat.generate_title_from_first_message

      begin
        upsert_recommended_films_from(clean)
      rescue StandardError => e
        Rails.logger.warn("[recommended_films] #{e.class}: #{e.message}")
      end

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
    params.require(:message).permit(:content)
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

  def call_ruby_llm(user_text)
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-mini")
    response = ruby_llm_chat.with_instructions(instructions).ask(user_text)
    response.content.to_s
  end

  def normalize_ai_text(text)
    s = text.to_s.gsub(/\r\n?/, "\n").strip

    # Remove markdown headings like "# Title"
    s = s.gsub(/^\s{0,3}\#{1,6}\s+/, "")

    # Normalize bullets to "• "
    s = s.gsub(/^\s*[-*]\s+/, "• ")

    # Split jammed bullets
    s = s.gsub(/\s+•\s+/, "\n• ")

    # Force Refine on its own line
    s = s.gsub(/\s*Refine:\s*/m, "\n\nRefine:\n")

    # Cleanup whitespace
    s = s.gsub(/[ \t]+\n/, "\n")
    s = s.gsub(/\n{3,}/, "\n\n").strip

    lines = s.split("\n").map(&:rstrip)
    lines.reject! { |l| l.strip.empty? || l.strip == "•" }

    refine_index = lines.index { |l| l.strip.casecmp("Refine:").zero? }

    film_lines =
      if refine_index
        lines[0...refine_index]
      else
        lines
      end

    refine_lines =
      if refine_index
        lines[(refine_index + 1)..] || []
      else
        []
      end

    film_lines = film_lines.select { |l| l.strip.start_with?("•") }.first(MAX_FILMS)
    refine_lines = refine_lines.select { |l| l.strip.start_with?("•") }.first(REFINE_BULLETS)

    if refine_lines.length < REFINE_BULLETS
      defaults = [
        "• Want more gore vs. paranormal?",
        "• Pick a runtime cap (e.g., < 100 min).",
        "• Choose era: classics, 2000s, or modern."
      ]
      refine_lines += defaults[refine_lines.length...REFINE_BULLETS]
    end

    (film_lines + ["", "Refine:"] + refine_lines).join("\n").strip
  end

  def upsert_recommended_films_from(clean_text)
    films = parse_film_bullets(clean_text)
    return if films.empty?

    films.each do |film|
      rec = RecommendedFilm.find_or_initialize_by(
        chat: @chat,
        watch_session: @watch_session,
        title: film[:title],
        year: film[:year]
      )

      rec.runtime = film[:runtime] if film[:runtime].present?
      rec.blurb = film[:blurb] if film[:blurb].present?
      rec.added = false if rec.new_record? && rec.respond_to?(:added)

      rec.save!
    end
  end

  def parse_film_bullets(text)
    lines = text.to_s.split("\n").map(&:strip)
    film_lines = lines.take_while { |l| !l.casecmp("Refine:").zero? }

    film_lines = film_lines.select { |l| l.start_with?("•") }

    film_lines.map do |line|
      # Example:
      # • **Insidious (2010)** — 103 min: Masterful jump scares...
      title = nil
      year = nil
      runtime = nil
      blurb = nil

      if (m = line.match(/\*\*(.+?)\s*\((\d{4})\)\*\*/))
        title = m[1].strip
        year = m[2].to_i
      end

      if (m = line.match(/—\s*(\d+)\s*min/i))
        runtime = m[1].to_i
      end

      if (m = line.match(/min:\s*(.+)\z/i))
        blurb = m[1].strip
      elsif (m = line.match(/\)\*\*\s*—\s*\d+\s*min:\s*(.+)\z/i))
        blurb = m[1].strip
      end

      next if title.blank? || year.blank?

      { title: title, year: year, runtime: runtime, blurb: blurb }
    end.compact
  end
end
