class ChatsController < ApplicationController

  def create
    @watch_session = WatchSession.find(params[:watch_session_id])

    @chat = Chat.new(title: "Untitled")
    @chat.watch_session = @watch_session
    @chat.user = current_user

    if @chat.save
      redirect_to chat_path(@chat)
    else
      @chats = @watch_session.chats.where(user: current_user)
      render "watch_sessions/show"
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @messages = @chat.messages.order(:created_at)
    @message = Message.new
  end

end
