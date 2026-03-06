require "net/http"
require "json"

class TmdbMovieLookup
  def initialize(title:, year: nil)
    @title = title
    @year = year
    @api_key = ENV.fetch("TMDB_API_KEY", nil)
  end

  def call
    return {} if @api_key.blank?

    uri = URI("https://api.themoviedb.org/3/search/movie")
    params = {
      api_key: @api_key,
      query: @title
    }
    params[:year] = @year if @year.present?
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} unless response.is_a?(Net::HTTPSuccess)

    json = JSON.parse(response.body)
    movie = json["results"]&.first
    return {} if movie.blank?

    {
      poster_url: poster_url_for(movie["poster_path"])
    }
  rescue StandardError => e
    Rails.logger.warn("TMDB lookup failed: #{e.message}")
    {}
  end

  private

  def poster_url_for(poster_path)
    return nil if poster_path.blank?

    "https://image.tmdb.org/t/p/w500#{poster_path}"
  end
end
