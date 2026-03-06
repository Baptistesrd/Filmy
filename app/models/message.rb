class Message < ApplicationRecord
  belongs_to :chat

  has_one_attached :image

  validates :role, presence: true
  validates :content, presence: true, unless: :content_optional?

  enum :role, { user: "user", assistant: "assistant" }

  after_create_commit :broadcast_append_to_chat

  private

  def content_optional?
    image.attached? || (assistant? && content.blank?)
  end
end
