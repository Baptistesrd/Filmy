class SwipeController < ApplicationController
  def index
    seen_ids = current_user.swipe_preferences.pluck(:tmdb_id)
    page     = (params[:page] || 1).to_i

    @films = TmdbService.popular_films(page: page).reject do |f|
      seen_ids.include?(f[:tmdb_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: @films }
    end
  end
end
