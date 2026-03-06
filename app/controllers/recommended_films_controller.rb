class RecommendedFilmsController < ApplicationController
  def add
    @recommended_film =
      RecommendedFilm
      .joins(:watch_session)
      .where(watch_sessions: { user_id: current_user.id })
      .find(params[:id])

    @chat = current_user.chats.find(@recommended_film.chat_id)
    watch_session = @recommended_film.watch_session

    watch_session.films.create!(
      title: @recommended_film.title,
      year: @recommended_film.year,
      runtime: @recommended_film.runtime,
      genre: watch_session.genre,
      streaming_services: @recommended_film.try(:streaming_services),
      justwatch_url: @recommended_film.try(:justwatch_url)
    )

    @recommended_film.update!(added: true)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end
end
