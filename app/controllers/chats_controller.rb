class ChatsController < ApplicationController
  def create
    watch_session = current_user.watch_sessions.find(params[:watch_session_id])
    chat = watch_session.chats.create!(title: Chat::DEFAULT_TITLE)
    redirect_to chat_path(chat)
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end
end
