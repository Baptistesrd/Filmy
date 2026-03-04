class WatchSession < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  def context_prompt
    <<~TEXT
    You are helping with a watch session.

    Title: #{title}
    Description: #{description}
    Movie/Show: #{movie_or_show_name}
    Genre: #{genre}
    Mood: #{mood}
    TEXT
  end
end
