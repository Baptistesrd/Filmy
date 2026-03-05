class Message < ApplicationRecord
  belongs_to :chat

  validates :role, presence: true
  validates :content, presence: true

  has_one_attached :file
  
end
