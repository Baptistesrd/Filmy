class RatingsController < ApplicationController
  def create
    @film   = current_user.films.find(params[:film_id])
    @rating = @film.ratings.find_or_initialize_by(user: current_user)
    @rating.score  = params[:score]
    @rating.review = params[:review]

    if @rating.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: films_path }
      end
    else
      redirect_back fallback_location: films_path, alert: "Could not save rating."
    end
  end

  def destroy
    @rating = current_user.ratings.find(params[:id])
    @rating.destroy
    redirect_back fallback_location: films_path
  end
end
