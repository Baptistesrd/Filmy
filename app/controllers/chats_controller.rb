class ChatsController < ApplicationController
  def create
    watch_session = current_user.watch_sessions.find(params[:watch_session_id])

    chat = watch_session.chats.new(title: Chat::DEFAULT_TITLE)
    chat.user = current_user
    chat.save!

    redirect_to chat_path(chat)
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
    @recommended_films = @chat.recommended_films.order(created_at: :desc)
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    watch_session = @chat.watch_session
    @chat.destroy

    redirect_to watch_session_path(watch_session)
  end
end
