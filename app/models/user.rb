class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :watch_sessions, dependent: :destroy
  has_many :chats, through: :watch_sessions
  validates :name, :email, :password, presence: true
  validates :email, uniqueness: true
end
