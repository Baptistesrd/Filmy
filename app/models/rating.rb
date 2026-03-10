class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :film

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :film_id, message: "has already rated this film" }
end
