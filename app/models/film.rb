class Film < ApplicationRecord
  belongs_to :watch_session

  validates :title, presence: true
end
