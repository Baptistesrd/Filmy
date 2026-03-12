require "net/http"
require "json"

class TmdbService
  BASE_URL   = "https://api.themoviedb.org/3"
  IMAGE_BASE = "https://image.tmdb.org/t/p/w500"

  CATEGORIES = %w[popular trending top_rated hidden_gems].freeze

  # Unified discover method — routes to different TMDB endpoints by category.
  def self.discover_films(page: 1, category: "popular")
    api_key = ENV.fetch("TMDB_API_KEY", nil)
    return [] if api_key.blank?

    category = "popular" unless CATEGORIES.include?(category.to_s)

    Rails.cache.fetch("tmdb_discover_v2/#{category}/#{page}", expires_in: 2.hours) do
      url      = build_discover_url(api_key, category.to_s, page)
      response = Net::HTTP.get_response(URI(url))
      next [] unless response.is_a?(Net::HTTPSuccess)

      (JSON.parse(response.body)["results"] || []).map { |m| map_film(m) }
    end
  rescue StandardError => e
    Rails.logger.warn("TmdbService.discover_films error: #{e.message}")
    []
  end

  # Legacy alias kept for compatibility.
  def self.popular_films(page: 1)
    discover_films(page: page, category: "popular")
  end

  def self.build_discover_url(api_key, category, page)
    base   = "#{BASE_URL}"
    common = "api_key=#{api_key}&language=en-US&page=#{page}"

    case category
    when "trending"
      "#{base}/trending/movie/week?#{common}"
    when "top_rated"
      "#{base}/movie/top_rated?#{common}"
    when "hidden_gems"
      # High-rated films most people haven't seen
      "#{base}/discover/movie?#{common}&sort_by=vote_average.desc" \
        "&vote_count.gte=150&vote_count.lte=2500&vote_average.gte=7.4"
    else
      "#{base}/movie/popular?#{common}"
    end
  end
  private_class_method :build_discover_url

  def self.map_film(m)
    {
      tmdb_id:     m["id"],
      title:       m["title"],
      year:        (Date.parse(m["release_date"]).year rescue nil if m["release_date"].present?),
      poster_url:  m["poster_path"].present? ? "#{IMAGE_BASE}#{m['poster_path']}" : nil,
      synopsis:    m["overview"],
      tmdb_rating: m["vote_average"]&.round(1)
    }
  end
  private_class_method :map_film

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
