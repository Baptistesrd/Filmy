class AddColumnsToWatchSession < ActiveRecord::Migration[8.1]
  def change
    add_column :watch_sessions, :title, :string
    add_column :watch_sessions, :description, :string
    add_column :watch_sessions, :movie_or_show_name, :string
  end
end
