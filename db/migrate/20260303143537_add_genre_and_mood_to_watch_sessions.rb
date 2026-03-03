class AddGenreAndMoodToWatchSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :watch_sessions, :genre, :string
    add_column :watch_sessions, :mood, :string
  end
end
