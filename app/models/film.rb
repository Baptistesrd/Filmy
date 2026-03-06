class Film < ApplicationRecord
  belongs_to :watch_session

  validates :title, presence: true

  def justwatch_url
    slug = title.parameterize
    "https://www.justwatch.com/uk/movie/#{slug}"
  end
end
