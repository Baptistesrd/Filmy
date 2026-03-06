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

      broadcast_append(@message)
      broadcast_append(@assistant_message)

      if @message.image.attached?
        send_image_question
      else
        send_question
      end

      cleaned_content = normalize_ai_text(@assistant_message.content)
      @assistant_message.update_column(:content, cleaned_content)

      broadcast_replace(@assistant_message)

      upsert_recommended_films_from(cleaned_content)
      broadcast_recommended_panel

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
    ruby_llm_chat.with_instructions([image_instructions, watch_session_context].compact.join("\n\n"))

    build_conversation_history(ruby_llm_chat)

    ruby_llm_chat.ask(
      "Analyze this image and recommend films with a similar cinematic atmosphere.",
      with: { image: @message.image.url }
    ) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  end

  def broadcast_append(message)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{@chat.id}",
      target: "message_#{message.id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def broadcast_recommended_panel
    recommended_films = @chat.recommended_films.order(created_at: :desc)

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{@chat.id}",
      target: "recommended_panel",
      partial: "recommended_films/panel",
      locals: { chat: @chat, recommended_films: recommended_films }
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
    s = s.gsub(/\s*•\s*/, "\n• ")
    s = s.gsub(/\s*Refine:\s*/i, "\n\nRefine:\n")
    s = s.gsub(/(?<=\S)\s+•\s+/, "\n• ")
    s = s.gsub(/[ \t]+\n/, "\n")
    s = s.gsub(/\n{3,}/, "\n\n").strip

    lines = s.split("\n").map(&:strip)
    lines.reject!(&:blank?)

    refine_index = lines.index { |line| line.casecmp("Refine:").zero? }

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

    film_lines = film_lines.select { |line| line.start_with?("•") }.first(MAX_FILMS)
    refine_lines = refine_lines.select { |line| line.start_with?("•") }.first(REFINE_BULLETS)

    if refine_lines.length < REFINE_BULLETS && refine_index.present?
      defaults = [
        "• Want more gore vs. paranormal?",
        "• Pick a runtime cap (e.g., < 100 min).",
        "• Choose era: classics, 2000s, or modern."
      ]
      refine_lines += defaults[(refine_lines.length)...REFINE_BULLETS]
    end

    output = []
    output.concat(film_lines)

    if refine_index.present?
      output << ""
      output << "Refine:"
      output.concat(refine_lines)
    end

    output.join("\n").strip
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
    film_section = clean_text.to_s.split(/^Refine:\s*$/i).first.to_s

    film_section
      .split("\n")
      .map(&:strip)
      .select { |line| line.start_with?("•") }
      .map { |line| parse_film_line(line) }
      .compact
  end

  def parse_film_line(line)
    s = line.sub(/\A•\s*/, "").strip
    s = s.gsub(/\*\*(.*?)\*\*/, '\1')

    match = s.match(/\A(.+?)\s*\((\d{4})\)\s*—\s*(\d{1,3})\s*min:\s*(.+)\z/)
    return nil unless match

    {
      title: match[1].strip,
      year: match[2].to_i,
      runtime: match[3].to_i,
      blurb: match[4].strip
    }
  end
end
