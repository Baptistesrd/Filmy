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
  include ActionView::RecordIdentifier

  MIN_FILMS = 4
  MAX_FILMS = 6
  REFINE_BULLETS = 3

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session

    @message = @chat.messages.new(message_params)
    @message.role = "user"

    if @message.save
      @assistant_message = @chat.messages.create!(role: "assistant", content: "")

      if @message.image.attached?
        send_image_question
      else
        send_question
      end

      @assistant_message.update_column(:content, normalize_ai_text(@assistant_message.content))

      broadcast_replace(@assistant_message)
      clean_text = @assistant_message.content
      upsert_recommended_films_from(clean_text)

      @chat.generate_title_from_first_message
      @recommended_films = @chat.recommended_films.order(created_at: :desc)

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

  def send_question
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-mini")
    ruby_llm_chat.with_instructions(instructions)

    build_conversation_history(ruby_llm_chat)

    ruby_llm_chat.ask(@message.content) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def send_image_question
    ruby_llm_chat = RubyLLM.chat(model: "gpt-4.1-mini")
    ruby_llm_chat.with_instructions(image_instructions)

    build_conversation_history(ruby_llm_chat)

    ruby_llm_chat.ask(
      "Analyze this image and recommend films with a similar cinematic atmosphere.",
      with: { image: url_for(@message.image) }
    ) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: dom_id(message),
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def build_conversation_history(ruby_llm_chat)
    @chat.messages.order(:created_at).each do |message|
      next if message.content.blank?

      ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def message_params
    params.require(:message).permit(:content, :image)
  end

  def watch_session_context
    return nil unless @watch_session

    "Watch session context:\n" \
      "- genre: #{@watch_session.genre}\n" \
      "- mood: #{@watch_session.mood}\n" \
      "- title: #{@watch_session.title}\n" \
      "- description: #{@watch_session.description}"
  end

  def instructions
    [SYSTEM_PROMPT, watch_session_context].compact.join("\n\n")
  end

  def image_instructions
    <<~PROMPT
      You are a movie recommendation assistant.

      When the user uploads an image:
      - Analyze the aesthetic, lighting, color palette, and mood.
      - Recommend exactly 3-5 movies with a similar cinematic atmosphere.

      Response format:
      • **Movie Title (Year)** — Runtime min: short explanation.

      Rules:
      - Do NOT add tips.
      - Do NOT suggest ways to refine the search.
      - Do NOT add extra sections.
      - Only return the movie list.
    PROMPT
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

    if refine_lines.any?
      out = []
      out.concat(film_lines)
      out << ""
      out << "Refine:"
      out.concat(refine_lines)
      out.join("\n").strip
    else
      film_lines.join("\n").strip
    end
  end

  def upsert_recommended_films_from(clean_text)
    films = extract_films_from(clean_text)

    films.each do |film|
      record = @chat.recommended_films.where(title: film[:title], year: film[:year]).first_or_initialize

      record.watch_session = @watch_session
      record.runtime = film[:runtime]
      record.blurb = film[:blurb]
      record.added = false if record.added.nil?

      record.save!
    end
  end

  def extract_films_from(clean_text)
    film_lines = clean_text.to_s.lines
                           .map(&:strip)
                           .take_while { |line| !line.casecmp("Refine:").zero? }
                           .select { |line| line.start_with?("•") }

    film_lines.map { |line| parse_film_line(line) }.compact
  end

  def parse_film_line(line)
    s = line.sub(/\A•\s*/, "").strip

    title_year, rest = s.split("—", 2).map { |x| x.to_s.strip }
    return nil if title_year.blank?

    title_year = title_year.gsub(/\*\*(.*?)\*\*/, '\1').strip

    title = title_year
    year = nil

    if (m = title_year.match(/\A(.+?)\s*\((\d{4})\)\z/))
      title = m[1].strip
      year = m[2].to_i
    end

    runtime = nil
    blurb = nil

    if rest.present?
      if (rm = rest.match(/(\d{1,3})\s*min/i))
        runtime = rm[1].to_i
      end

      parts = rest.split(":", 2).map { |x| x.to_s.strip }
      blurb = parts.length == 2 ? parts[1] : rest
      blurb = blurb.to_s.strip
    end

    { title: title, year: year, runtime: runtime, blurb: blurb }
  end
end
