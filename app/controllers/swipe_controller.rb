class SwipeController < ApplicationController
  VALID_CATEGORIES = TmdbService::CATEGORIES

  def index
    @category = sanitize_category(params[:category])
    seen_ids  = current_user.swipe_preferences.pluck(:tmdb_id)
    page      = (params[:page] || 1).to_i

    @films = TmdbService.discover_films(page: page, category: @category).reject do |f|
      seen_ids.include?(f[:tmdb_id])
    end

    respond_to do |format|
      format.html
      format.json { render json: @films }
    end
  end

  def recommend
    liked    = current_user.swipe_preferences.liked.order(created_at: :desc).limit(20)
    disliked = current_user.swipe_preferences.disliked.order(created_at: :desc).limit(10)

    return render json: { error: "no_likes" }, status: :unprocessable_entity if liked.empty?

    liked_list    = liked.map    { |f| f.year ? "#{f.title} (#{f.year})" : f.title }.join(", ")
    disliked_list = disliked.map { |f| f.title }.join(", ")

    prompt = <<~PROMPT
      A film lover's taste profile:

      LOVED: #{liked_list}
      #{disliked_list.present? ? "DISLIKED: #{disliked_list}" : ""}

      Based on what they loved (and what they skipped), recommend exactly ONE film that:
      - Matches the emotional tone, themes, and style of their liked films
      - Is NOT already in the loved or disliked list
      - Can be a hidden gem, an acclaimed classic, or a recent release — anything goes

      Respond ONLY with valid JSON, no markdown, no extra text:
      {
        "title": "Exact film title",
        "year": 2015,
        "message": "A warm, personal 2–3 sentence message written like a knowledgeable friend. Reference 1–2 specific films from their loved list by name and explain the connection concretely."
      }
    PROMPT

    response  = RubyLLM.chat(model: "gpt-4o").ask(prompt)
    json_text = response.content.gsub(/```(?:json)?\n?|\n?```/, "").strip
    data      = JSON.parse(json_text)

    tmdb = TmdbService.new(title: data["title"], year: data["year"]).call

    render json: {
      title:       data["title"],
      year:        data["year"],
      message:     data["message"],
      poster_url:  tmdb[:poster_url],
      rating:      tmdb[:rating],
      director:    tmdb[:director],
      trailer_url: tmdb[:trailer_url]
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Discover recommend parse error: #{e.message}")
    render json: { error: "parse_error" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Discover recommend error: #{e.message}")
    render json: { error: "failed" }, status: :unprocessable_entity
  end

  private

  def sanitize_category(value)
    VALID_CATEGORIES.include?(value.to_s) ? value.to_s : "popular"
  end
end
