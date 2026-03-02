class AddChatToConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :chat, null: false, foreign_key: true
  end
end
