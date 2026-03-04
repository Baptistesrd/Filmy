class Message < ApplicationRecord
  belongs_to :chat

  validates :role, presence: true
  validates :content, presence: true

  enum :role, { user: 0, assistant: 1 }
end
