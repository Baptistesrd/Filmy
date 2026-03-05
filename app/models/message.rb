class Message < ApplicationRecord
  belongs_to :chat

  validates :role, presence: true
  validates :content, presence: true, unless: -> { image.attached? }

  enum :role, { user: "user", assistant: "assistant" }

  has_one_attached :image
end
