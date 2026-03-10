class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :recommended_film

  enum :rating_type, { thumbs_up: "thumbs_up", thumbs_down: "thumbs_down" }

  validates :rating_type, presence: true
  validates :user_id, uniqueness: { scope: :recommended_film_id, message: "has already given feedback" }
end
