class SwipePreference < ApplicationRecord
  belongs_to :user

  validates :tmdb_id, :title, :liked, presence: true
  validates :tmdb_id, uniqueness: { scope: :user_id }

  scope :liked,    -> { where(liked: true) }
  scope :disliked, -> { where(liked: false) }
end
