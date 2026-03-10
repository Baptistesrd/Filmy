require "net/http"
require "json"

class TmdbService
  BASE_URL   = "https://api.themoviedb.org/3"
  IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

  # Returns an array of film hashes from TMDB's popular endpoint.
  def self.popular_films(page: 1)
    api_key = ENV.fetch("TMDB_API_KEY", nil)
    return [] if api_key.blank?

    Rails.cache.fetch("tmdb_popular_v1/page_#{page}", expires_in: 1.hour) do
      uri      = URI("#{BASE_URL}/movie/popular?api_key=#{api_key}&page=#{page}&language=en-US")
      response = Net::HTTP.get_response(uri)
      next [] unless response.is_a?(Net::HTTPSuccess)

      results = JSON.parse(response.body)["results"] || []
      results.map do |m|
        {
          tmdb_id:     m["id"],
          title:       m["title"],
          year:        m["release_date"]&.then { |d| Date.parse(d).year rescue nil },
          poster_url:  m["poster_path"].present? ? "#{IMAGE_BASE}#{m['poster_path']}" : nil,
          synopsis:    m["overview"],
          tmdb_rating: m["vote_average"]&.round(1),
          genre:       nil  # genre_ids only on list endpoint; omit for performance
        }
      end
    end
  rescue StandardError => e
    Rails.logger.warn("TmdbService.popular_films error: #{e.message}")
    []
  end

  def initialize(title:, year: nil)
    @title   = title
    @year    = year
    @api_key = ENV.fetch("TMDB_API_KEY", nil)
  end

  def call
    return {} if @api_key.blank?

    Rails.cache.fetch(cache_key, expires_in: 24.hours) { fetch_all }
  rescue StandardError => e
    Rails.logger.warn("TmdbService error: #{e.message}")
    {}
  end

  private

  def cache_key
    "tmdb_v2/#{@title.parameterize}/#{@year}"
  end

  def fetch_all
    movie = search_movie
    return {} if movie.blank?

    id      = movie["id"]
    details = get_json("#{BASE_URL}/movie/#{id}?api_key=#{@api_key}") || {}
    credits = get_json("#{BASE_URL}/movie/#{id}/credits?api_key=#{@api_key}") || {}
    videos  = get_json("#{BASE_URL}/movie/#{id}/videos?api_key=#{@api_key}") || {}

    {
      tmdb_id:         id,
      poster_url:      poster_url_for(movie["poster_path"]),
      synopsis:        details["overview"],
      rating:          details["vote_average"]&.round(1),
      runtime:         details["runtime"],
      genre:           details["genres"]&.map { |g| g["name"] }&.first(2)&.join(", "),
      director:        director_from(credits),
      cast_members:    cast_from(credits),
      trailer_url:     trailer_from(videos)
    }
  end

  def search_movie
    uri = URI("#{BASE_URL}/search/movie")
    params = { api_key: @api_key, query: @title }
    params[:year] = @year if @year.present?
    uri.query = URI.encode_www_form(params)

    result = get_json(uri.to_s)
    result&.dig("results")&.first
  end

  def get_json(url)
    response = Net::HTTP.get_response(URI(url))
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def poster_url_for(path)
    path.present? ? "#{IMAGE_BASE}#{path}" : nil
  end

  def director_from(credits)
    (credits["crew"] || []).find { |c| c["job"] == "Director" }&.dig("name")
  end

  def cast_from(credits)
    (credits["cast"] || []).first(3).map { |c| c["name"] }.join(", ")
  end

  def trailer_from(videos)
    trailer = (videos["results"] || []).find { |v| v["type"] == "Trailer" && v["site"] == "YouTube" }
    trailer ? "https://www.youtube.com/watch?v=#{trailer['key']}" : nil
  end
end
