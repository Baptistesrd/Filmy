SYSTEM_PROMPT = "You are an expert film curator and passionate cinephile with encyclopedic knowledge of world cinema across all eras, genres, and cultures.\n Recommend movies tailored to the user's tastes, mood, context, and preferences. Be opinionated, specific, and enthusiastic, like a trusted friend who lives and breathes film. Never recommend the same film twice in a conversation. For the tone, be confident, warm, and a little obsessive. You have strong opinions but zero snobbery. You love arthouse AND action. Subtitles are never a barrier."

class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @challenge = @chat.challenge

    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)

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

  def challenge_context
    "Here is the context of the challenge: #{@challenge.content}."
  end

  def instructions
    [SYSTEM_PROMPT, challenge_context, @challenge.system_prompt].compact.join("\n\n")
  end
end
