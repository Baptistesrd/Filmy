class RecommendedFilm < ApplicationRecord
  belongs_to :chat
  belongs_to :watch_session
  has_many :feedbacks, dependent: :destroy

  scope :not_added, -> { where(added: false) }
  scope :added,     -> { where(added: true) }
end
