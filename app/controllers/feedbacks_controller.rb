class FeedbacksController < ApplicationController
  def create
    @recommended_film = RecommendedFilm
      .joins(:watch_session)
      .where(watch_sessions: { user_id: current_user.id })
      .find(params[:recommended_film_id])

    @feedback = @recommended_film.feedbacks.find_or_initialize_by(user: current_user)
    @feedback.rating_type = params[:rating_type]

    if @feedback.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    feedback = current_user.feedbacks.find(params[:id])
    feedback.destroy
    head :ok
  end
end
