class FilmsController < ApplicationController
  before_action :set_film, only: [:destroy]

  def index
    @films = current_user.films.recent
  end

  def destroy
    @film.destroy
    redirect_to films_path, notice: "Removed from your library."
  end

  private

  def set_film
    @film = current_user.films.find(params[:id])
  end
end
