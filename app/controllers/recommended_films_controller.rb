class RecommendedFilmsController < ApplicationController
  def add
    @recommended_film = RecommendedFilm.find(params[:id])

    @chat = current_user.chats.find(@recommended_film.chat_id)

    Film.create!(
      title: @recommended_film.title,
      genre: @chat.watch_session.genre,
      watch_session_id: @chat.watch_session_id,
      year: @recommended_film.year
    )

    @recommended_film.update!(added: true)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end
end
