class Message < ApplicationRecord
  bbelongs_to :chat

  validates :role, presence: true
  validates :content, presence: true
end
