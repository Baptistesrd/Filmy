class SwipePreferencesController < ApplicationController
  def create
    pref = current_user.swipe_preferences.find_or_initialize_by(
      tmdb_id: swipe_params[:tmdb_id]
    )
    pref.assign_attributes(swipe_params)

    if pref.save
      render json: { status: "ok" }
    else
      render json: { status: "error", errors: pref.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def swipe_params
    params.require(:swipe_preference).permit(
      :tmdb_id, :title, :year, :poster_url, :genre, :synopsis, :tmdb_rating, :liked
    )
  end
end
