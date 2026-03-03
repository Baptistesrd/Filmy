class WatchSessionsController < ApplicationController
<<<<<<< HEAD
  def new
    @session = Session.new
  end

  def create
    @watch_session = WatchSession.new(watch_session_params)

    if @watch_session.save
      redirect_to @watch_session, notice: "Watch session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def watch_session_params
    params.require(:watch_session).permit(:title, :description, :movie_or_show_name, :start_time, :end_time)
  end

=======
  def show
    @watch_session = current_user.watch_sessions.find(params[:id])
    @messages = @watch_session.messages.order(:created_at)
    @message = Message.new
  end
>>>>>>> 9086d64c4ff28c6c1938869af373de292fe6c3d1
end
