class RecommendedFilm < ApplicationRecord
  belongs_to :chat
  belongs_to :watch_session

  validates :title, presence: true
end
