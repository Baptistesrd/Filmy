class RecommendedFilmsController < ApplicationController
  def add
    recommended_film = current_user_recommended_films.find(params[:id])

    film = Film.new(watch_session: recommended_film.watch_session)

    film.title = recommended_film.title if film.respond_to?(:title=)
    film.year = recommended_film.year if film.respond_to?(:year=) && recommended_film.year.present?
    film.runtime = recommended_film.runtime if film.respond_to?(:runtime=) && recommended_film.runtime.present?
    film.description = recommended_film.blurb if film.respond_to?(:description=) && recommended_film.blurb.present?

    film.save!

    recommended_film.update!(added: true)

    respond_to do |format|
      format.turbo_stream do
        chat = recommended_film.chat
        recommended_films = chat.recommended_films.order(created_at: :desc)

        render turbo_stream: turbo_stream.replace(
          "recommended_panel",
          partial: "recommended_films/panel",
          locals: { chat: chat, recommended_films: recommended_films }
        )
      end
      format.html { redirect_back fallback_location: watch_session_path(recommended_film.watch_session) }
    end
  end

  private

  def current_user_recommended_films
    RecommendedFilm
      .joins(:watch_session)
      .where(watch_sessions: { user_id: current_user.id })
  end
end
