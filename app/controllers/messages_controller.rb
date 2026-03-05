SYSTEM_PROMPT = "You are an expert film curator and passionate cinephile with encyclopedic knowledge of world cinema across all eras, genres, and cultures.\n Recommend movies tailored to the user's tastes, mood, context, and preferences. Be opinionated, specific, and enthusiastic, like a trusted friend who lives and breathes film. Never recommend the same film twice in a conversation. For the tone, be confident, warm, and a little obsessive. You have strong opinions but zero snobbery. You love arthouse AND action. Subtitles are never a barrier."

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
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)

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
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message_container", partial: "messages/form", locals: { chat: @chat, message: @message }) }
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
    temperature: 0.7 }
    )
    response.dig("choices", 0, "message", "content")
  end

  def process_file(file)
    if file.content_type == "application/pdf"
      @ruby_llm_chat = RubyLLM.chat(model: "gemini-2.0-flash")
        build_conversation_history
      @ruby_llm_chat.with_instructions(instructions)
      @response = @ruby_llm_chat.ask(@message.content, with: { pdf: @message.file.url })
    elsif file.image?
      @ruby_llm_chat = RubyLLM.chat(model: "gpt-4o")
        build_conversation_history
      @ruby_llm_chat.with_instructions(instructions)
      @response = @ruby_llm_chat.ask(@message.content, with: { image: @message.file.url })
    end
  end
end
