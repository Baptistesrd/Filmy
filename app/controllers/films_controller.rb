class FilmsController < ApplicationController
  def destroy
    watch_session = current_user.watch_sessions.find(params[:watch_session_id])
    film = watch_session.films.find(params[:id])

    film.destroy

    redirect_to edit_watch_session_path(watch_session), notice: "Film removed from watch session."
  end
end
