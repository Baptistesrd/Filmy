class CreateWatchSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :watch_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :genre
      t.string :mood

      t.timestamps
    end
  end
end
