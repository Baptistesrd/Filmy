class RecommendedFilm < ApplicationRecord
  belongs_to :chat
  belongs_to :watch_session

  scope :not_added, -> { where(added: false) }
end
