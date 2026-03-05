class Chat < ApplicationRecord
  belongs_to :watch_session
  belongs_to :user
  has_many :messages, dependent: :destroy

  DEFAULT_TITLE = "Untitled"

  validates :title, presence: true

  TITLE_PROMPT = <<~PROMPT
    Generate a short, descriptive title (3–6 words max).
    Output ONLY the title text on ONE line.
    No bullets, no punctuation-heavy output, no quotes.
  PROMPT

  def generate_title_from_first_message
    return unless title == DEFAULT_TITLE

    first_user_message = messages.where(role: "user").order(:created_at).first
    return unless first_user_message

    raw_title =
      begin
        response = RubyLLM.chat.with_instructions(TITLE_PROMPT).ask(first_user_message.content)
        response.content.to_s
      rescue StandardError
        ""
      end

    cleaned = clean_title(raw_title)

    if cleaned.blank? || cleaned.include?("—") || cleaned.include?("\n") || cleaned.length > 60
      cleaned = clean_title(first_user_message.content.to_s)
    end

    update(title: cleaned.presence || DEFAULT_TITLE)
  end

  private

  def clean_title(text)
    text.to_s
        .gsub(/\r\n?/, "\n")
        .lines.first.to_s
        .gsub(/\*\*(.*?)\*\*/, '\1')
        .gsub(/^[-*\d.)\s]+/, "")
        .gsub(/\s+/, " ")
        .strip
        .truncate(50)
  end
end
