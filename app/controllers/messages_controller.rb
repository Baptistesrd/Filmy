SYSTEM_PROMPT = "You are an expert film curator and passionate cinephile with encyclopedic knowledge of world cinema across all eras, genres, and cultures.

Recommend movies tailored to the user's tastes, mood, and context.

Keep responses concise and structured:
- Recommend 3-5 films maximum.
- Use bullet points.
- Each film should have only ONE short sentence explaining why it fits.
- Avoid long paragraphs.
- Keep the total response under ~120 words.

Never recommend the same film twice in a conversation.

After the recommendations, suggest 2-3 short ways the user could refine their search (for example: by genre, mood, decade, country, runtime, or intensity).

Tone: confident, warm, enthusiastic, and slightly obsessive about film, like a trusted friend who loves movies. You enjoy both arthouse and blockbuster cinema. Subtitles are never a barrier."

class MessagesController < ApplicationController
  def send_question(model: "gpt-4.1-nano", with: {})
    @ruby_llm_chat = RubyLLM.chat(model: model)
    # build_conversation_history/*
    @ruby_llm_chat.with_instructions(instructions)
    @response = @ruby_llm_chat.ask(@message.content, with: with)
  end

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat

      if @message.image.attached?

        image_url = @message.image.blob.url

        response = ruby_llm_chat.with_instructions(instructions).ask(
          "You are a movie recommendation assistant.
            When the user uploads an image:
            - Analyze the aesthetic, lighting, color palette and mood.
            - Recommend exactly 3–5 movies with a similar cinematic atmosphere.

            Response format:
            Movie Title (Year) — short explanation.

            Rules:
            - Do NOT add tips.
            - Do NOT suggest ways to refine the search.
            - Do NOT add extra sections.
            - Only return the movie list.",
          with: { image: image_url }
        )
      else
        response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      end

      Message.create(
        chat: @message.chat,
        content: response.content,
        role: "assistant"
      )

      @assistant_message = @chat.messages.create!(
        role: "assistant",
        content: response.content
      )

      @chat.generate_title_from_first_message

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("new_message_container", partial: "messages/form",
                                                                             locals: { chat: @chat, message: @message })
        end
        format.html { render "chats/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :image)
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

  def build_conversation_history
    @chat.messages.order(:created_at).where.not(role: nil).each do |message|
      @ruby_llm_chat.add_message(role: message.role, content: message.content)
    end
  end

  def call_llm(conversation)
    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: conversation,
        temperature: 0.7
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  def process_file
    return unless @message.image.attached?

    @ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")

    build_conversation_history
    @ruby_llm_chat.with_instructions(instructions)

    @response = @ruby_llm_chat.ask(
      "Analyze the aesthetic, color palette, lighting, and mood of this image.
        Then recommend 3-5 films with a similar cinematic atmosphere.",
      with: { image: url_for(@message.image) }
    )
  end
end
