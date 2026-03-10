class WatchSession < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy
  has_many :recommended_films, through: :chats

  validates :title, presence: true

  def context_prompt
    parts = []
    parts << "Genre: #{genre}" if genre.present?
    parts << "Mood: #{mood}" if mood.present?
    parts << "Description: #{description}" if description.present?
    return nil if parts.empty?

    "Session context — #{parts.join(' | ')}"
  end
end
