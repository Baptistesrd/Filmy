class DropWatchlistItems < ActiveRecord::Migration[8.1]
  def change
    drop_table :watchlist_items
  end
end
