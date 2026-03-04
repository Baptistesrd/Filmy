class WatchSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_watch_session, only: %i[show edit update destroy]

  def new
    @watch_session = WatchSession.new
  end

  def create
    @watch_session = WatchSession.new(watch_session_params)
    @watch_session.user = current_user

    if @watch_session.save
      redirect_to watch_session_path(@watch_session), notice: "Watch session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @message = Message.new
    @chats = @watch_session.chats
  end

  def edit
  end

  def update
    if @watch_session.update(watch_session_params)
      redirect_to watch_session_path(@watch_session), notice: "Watch session was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @watch_session.destroy
    redirect_to root_path, notice: "Watch session was successfully deleted."
  end

  private

  def set_watch_session
    @watch_session = current_user.watch_sessions.find(params[:id])
  end

  def watch_session_params
    params.require(:watch_session).permit(:title, :description, :genre, :mood, :movie_or_show_name)
  end

end
