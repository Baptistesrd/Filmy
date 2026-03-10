SYSTEM_PROMPT = <<~PROMPT
  You are Filmy — a warm, sharp, and slightly obsessive film companion. You have the taste of a seasoned cinephile and the ease of a great friend texting recommendations.

  FIRST, ask 2–3 natural clarifying questions about:
  - Mood or emotional state right now (not just genre — e.g. "do you want to feel something or escape everything?")
  - Energy level (want to be challenged, or sink into something?)
  - Era, language, or format preference if relevant

  WHEN recommending films, use this EXACT format for each:
  • **Title (Year)** — Runtime min: [why this matches their specific mood today, not just plot]. [One unexpected detail a casual viewer wouldn't know.]

  Additional rules:
  - Recommend 4–6 films per response, never fewer
  - Never recommend the same film twice in a conversation
  - After film bullets, add one blank line, then: Refine:
  - Then EXACTLY 3 follow-up suggestion bullets (starting with "• ")
  - Match the user's energy — casual message = casual tone. Specific = precise.
  - The unexpected detail must be genuinely surprising (production history, real events, director's note, etc.)
  - Zero snobbery. Great films exist in every genre and era.
PROMPT

class MessagesController < ApplicationController
  include ActionView::RecordIdentifier

  MAX_FILMS     = 6
  REFINE_BULLETS = 3

  def create
    @chat          = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session
    @message       = @chat.messages.new(message_params)
    @message.role  = "user"

    if @message.save
      @assistant_message = @chat.messages.create!(role: "assistant", content: "")

      broadcast_append(@message)
      broadcast_append(@assistant_message)

      if @message.image.attached?
        send_image_question
      else
        send_question
      end

      cleaned = normalize_ai_text(@assistant_message.content)
      @assistant_message.update_column(:content, cleaned)
      broadcast_replace(@assistant_message)

      upsert_recommended_films_from(cleaned)
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
    llm = RubyLLM.chat(model: "claude-sonnet-4-5")
    llm.with_instructions(instructions)
    build_history(llm)

    llm.ask(@message.content) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  rescue StandardError => e
    Rails.logger.error("Claude API error: #{e.message}")
    @assistant_message.update_column(:content, "I'm having trouble connecting right now. Mind trying again?")
    broadcast_replace(@assistant_message)
  end

  def send_image_question
    llm = RubyLLM.chat(model: "claude-sonnet-4-5")
    llm.with_instructions([image_instructions, @watch_session&.context_prompt].compact.join("\n\n"))
    build_history(llm)

    llm.ask(
      "Analyze this image and recommend films with a similar cinematic atmosphere.",
      with: { image: @message.image.url }
    ) do |chunk|
      next if chunk.content.blank?

      @assistant_message.content += chunk.content
      broadcast_replace(@assistant_message)
    end
  rescue StandardError => e
    Rails.logger.error("Claude vision error: #{e.message}")
    @assistant_message.update_column(:content, "I couldn't read that image. Try uploading it again?")
    broadcast_replace(@assistant_message)
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
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{@chat.id}",
      target: "recommended_panel",
      partial: "recommended_films/panel",
      locals: { chat: @chat, recommended_films: @chat.recommended_films.order(created_at: :desc) }
    )
  end

  def build_history(llm)
    @chat.messages.order(:created_at).each do |msg|
      next if msg.content.blank?

      llm.add_message(role: msg.role, content: msg.content)
    end
  end

  def message_params
    params.require(:message).permit(:content, :image)
  end

  def instructions
    parts = [SYSTEM_PROMPT]
    ctx   = @watch_session&.context_prompt
    parts << ctx if ctx.present?
    parts.join("\n\n")
  end

  def image_instructions
    <<~PROMPT
      You are a film recommendation assistant.
      When the user uploads an image, analyze its aesthetic, lighting, color palette, and mood.
      Recommend 3–5 films with a similar cinematic atmosphere.
      Format: • **Movie Title (Year)** — Runtime min: short explanation.
      Return only the film list. No tips, no extra sections.
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

    lines        = s.split("\n").map(&:strip).reject(&:blank?)
    refine_index = lines.index { |l| l.casecmp("Refine:").zero? }

    film_lines   = (refine_index ? lines[0...refine_index] : lines)
                   .select { |l| l.start_with?("•") }.first(MAX_FILMS)

    refine_lines = (refine_index ? lines[(refine_index + 1)..] || [] : [])
                   .select { |l| l.start_with?("•") }.first(REFINE_BULLETS)

    if refine_lines.length < REFINE_BULLETS && refine_index.present?
      defaults = [
        "• Want something shorter or longer?",
        "• Prefer a specific era — classic, 90s/2000s, or recent?",
        "• More intense or more comforting?"
      ]
      refine_lines += defaults[refine_lines.length...REFINE_BULLETS]
    end

    output = film_lines.dup
    if refine_index.present?
      output << ""
      output << "Refine:"
      output.concat(refine_lines)
    end

    output.join("\n").strip
  end

  def upsert_recommended_films_from(text)
    extract_films_from(text).each do |film|
      record = @chat.recommended_films
                    .where(title: film[:title], year: film[:year])
                    .first_or_initialize

      record.watch_session = @watch_session
      record.runtime       = film[:runtime]
      record.blurb         = film[:blurb]
      record.added         = false if record.added.nil?
      record.save!
    end
  end

  def extract_films_from(text)
    text.to_s.split(/^Refine:\s*$/i).first.to_s
        .split("\n").map(&:strip)
        .select { |l| l.start_with?("•") }
        .map { |l| parse_film_line(l) }
        .compact
  end

  def parse_film_line(line)
    s     = line.sub(/\A•\s*/, "").strip.gsub(/\*\*(.*?)\*\*/, '\1')
    match = s.match(/\A(.+?)\s*\((\d{4})\)\s*—\s*(\d{1,3})\s*min:\s*(.+)\z/)
    return nil unless match

    { title: match[1].strip, year: match[2].to_i, runtime: match[3].to_i, blurb: match[4].strip }
  end
end
