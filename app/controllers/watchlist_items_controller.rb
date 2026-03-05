class WatchlistItemsController < ApplicationController
  def create
    recommended_film = RecommendedFilm.find(params[:recommended_film_id])
    watch_session = recommended_film.watch_session

    item = watch_session.watchlist_items.find_or_initialize_by(
      title: recommended_film.title,
      year: recommended_film.year
    )
    item.runtime = recommended_film.runtime
    item.blurb = recommended_film.blurb
    item.save!

    recommended_film.update!(added: true)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: watch_session_path(watch_session) }
    end
  end

  def destroy
    item = WatchlistItem.find(params[:id])
    watch_session = item.watch_session
    item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: watch_session_path(watch_session) }
    end
  end
end
