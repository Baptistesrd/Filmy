class Film < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :rated,  -> { joins(:ratings) }

  def justwatch_lookup_url
    justwatch_url.presence || "https://www.justwatch.com/uk/movie/#{title.parameterize}"
  end

  def average_rating
    ratings.average(:score)&.round(1)
  end
end
