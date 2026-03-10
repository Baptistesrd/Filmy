class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :watch_sessions, dependent: :destroy
  has_many :chats, through: :watch_sessions
  has_many :films, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :swipe_preferences, dependent: :destroy
end
