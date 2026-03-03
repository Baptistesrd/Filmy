def create
  @watch_session = current_user.watch_sessions.find(params[:watch_session_id])
  @message = @watch_session.messages.build(message_params)
  @message.role = "user"

  if @message.save
    redirect_to watch_session_path(@watch_session)
  else
    render "watch_sessions/show", status: :unprocessable_entity
  end
end

private

def message_params
  params.require(:message).permit(:content)
end
