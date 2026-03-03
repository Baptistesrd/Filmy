class WatchSessionsController < ApplicationController
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

end
