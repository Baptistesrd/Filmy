class WatchSession < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  GENRES = [
    "Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary",
    "Drama", "Fantasy", "Horror", "Mystery", "Romance", "Sci-Fi",
    "Thriller", "War", "Western"
  ].freeze

  MOODS = [
    "Chill", "Feel-good", "Dark", "Funny", "Romantic", "Mind-bending",
    "Emotional", "High energy", "Scary", "Inspirational", "Cozy", "Weird"
  ].freeze
end
