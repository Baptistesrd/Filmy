class CreateWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :watchlist_items do |t|
      t.references :watch_session, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :year
      t.integer :runtime
      t.text :blurb

      t.timestamps
    end

    add_index :watchlist_items, [:watch_session_id, :title, :year], unique: true
  end
end
