class Message < ApplicationRecord
  belongs_to :chat

  validates :role, presence: true
  validates :content, presence: true

  enum :role, { user: "user", assistant: "assistant" }

  has_one_attached :file
  
end
