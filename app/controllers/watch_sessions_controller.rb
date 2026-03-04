class WatchSessionsController < ApplicationController
  def new
    @watch_session = WatchSession.new
  end

  def create
    @watch_session = WatchSession.new(watch_session_params)
    @watch_session.user = current_user

    if @watch_session.save
      redirect_to @watch_session, notice: "Watch session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @watch_session = WatchSession.find(params[:id])
    @message = Message.new
  end

  private

  def watch_session_params
    params.require(:watch_session).permit(:title, :description, :genre, :mood, :movie_or_show_name)
  end
end
