SYSTEM_PROMPT = <<~PROMPT
  You are an expert film curator and passionate cinephile.

  Rules for responses (VERY IMPORTANT):
  - Keep responses compact so they fit on one screen.
  - Recommend between 4-6 films.
  - Format each film as ONE bullet line ONLY, like:
    • **Title (Year)** — 112 min: short sentence. Second short sentence.
  - Do NOT add blank lines between film bullets.
  - After the last film bullet, output a divider line exactly:
    ====================
  - On the next line, write:
    Refine:
  - Then EXACTLY 3 bullet lines (no blank lines), each starting with "• ".

  Other rules:
  - Never recommend the same film twice in a conversation.
  - Be confident, warm, and a little obsessive. Zero snobbery.
PROMPT

class MessagesController < ApplicationController
  DIVIDER = "====================".freeze
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
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)

      clean = normalize_ai_text(response.content)

      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: clean,
        chat: @chat
      )

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

    s = s.gsub(/^\s{0,3}\#{1,6}\s+/, "")
    s = s.gsub(/^\s*-\s+/, "• ")
    s = s.gsub(/\s+Refine:\s*/m, "\nRefine:\n")
    s = s.gsub(/\n{3,}/, "\n\n")
    s = s.gsub(/[ \t]+\n/, "\n").strip

    lines = s.split("\n").map(&:rstrip).reject { |l| l.strip.empty? }

    refine_index = lines.index { |l| l.strip.casecmp("Refine:").zero? }

    if refine_index.nil?
      lines << "Refine:"
      refine_index = lines.length - 1
    end

    film_lines = lines[0...refine_index]
    refine_lines = lines[(refine_index + 1)..] || []

    film_bullets = film_lines
                   .select { |l| l.strip.start_with?("•") }
                   .first(6)

    film_bullets = film_bullets.first(4) if film_bullets.length < 4

    refine_bullets = refine_lines
                     .select { |l| l.strip.start_with?("•") }
                     .reject { |l| l.strip == "•" }
                     .first(3)

    if refine_bullets.length < 3
      refine_bullets = [
        "• Prefer newer or older films.",
        "• Focus on a specific subgenre.",
        "• Choose shorter or longer runtime."
      ]
    end

    out = []
    out.concat(film_bullets)
    out << ""
    out << "Refine:"
    out.concat(refine_bullets)

    out.join("\n").strip
  end
end
