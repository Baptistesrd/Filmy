SYSTEM_PROMPT = "You are an expert film curator and passionate cinephile with encyclopedic knowledge of world cinema across all eras, genres, and cultures.\n Recommend movies tailored to the user's tastes, mood, context, and preferences. Be opinionated, specific, and enthusiastic, like a trusted friend who lives and breathes film. Never recommend the same film twice in a conversation. For the tone, be confident, warm, and a little obsessive. You have strong opinions but zero snobbery. You love arthouse AND action. Subtitles are never a barrier."

class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @watch_session = @chat.watch_session

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)
      conversation = build_conversation(@watch_session)
      @chat.generate_title_from_first_message
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def watch_session_context
    "Here is the context of the watch_session: genre: #{@watch_session.genre}, mood: #{@watch_session.mood}, title: #{@watch_session.title}, description: #{@watch_session.description}."
  end

  def instructions
    [SYSTEM_PROMPT, watch_session_context].compact.join("\n\n")
  end

  def build_conversation(watch_session)
    messages = @chat.messages.order(:created_at)
    [
      { role: "system", content: watch_session.context_prompt }
      ] + messages.map do |msg| { role: msg.role, content: msg.content}
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
end
