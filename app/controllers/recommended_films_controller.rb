class RecommendedFilmsController < ApplicationController
  before_action :set_recommended_film

  def save_to_library
    tmdb = TmdbService.new(title: @recommended_film.title, year: @recommended_film.year).call

    current_user.films.find_or_create_by!(
      tmdb_id: tmdb[:tmdb_id].presence,
      title:   @recommended_film.title
    ) do |film|
      film.year         = @recommended_film.year
      film.runtime      = tmdb[:runtime]  || @recommended_film.runtime
      film.genre        = tmdb[:genre]
      film.poster_url   = tmdb[:poster_url]
      film.synopsis     = tmdb[:synopsis]
      film.director     = tmdb[:director]
      film.cast_members = tmdb[:cast_members]
      film.trailer_url  = tmdb[:trailer_url]
      film.rating       = tmdb[:rating]
      film.blurb        = @recommended_film.blurb
    end

    @recommended_film.update!(added: true)

    @chat = current_user.chats.find(@recommended_film.chat_id)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  private

  def set_recommended_film
    @recommended_film = RecommendedFilm
      .joins(:watch_session)
      .where(watch_sessions: { user_id: current_user.id })
      .find(params[:id])
  end
end
