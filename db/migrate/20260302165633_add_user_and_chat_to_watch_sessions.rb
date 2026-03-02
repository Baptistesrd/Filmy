class AddUserAndChatToWatchSessions < ActiveRecord::Migration[8.1]
  def change
    add_reference :watch_sessions, :user, null: false, foreign_key: true
    add_reference :watch_sessions, :chat, null: false, foreign_key: true
  end
end
