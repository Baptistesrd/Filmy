class CreateSwipePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :swipe_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.integer    :tmdb_id,    null: false
      t.string     :title,      null: false
      t.integer    :year
      t.string     :poster_url
      t.string     :genre
      t.text       :synopsis
      t.decimal    :tmdb_rating, precision: 3, scale: 1
      t.boolean    :liked,       null: false

      t.timestamps
    end

    add_index :swipe_preferences, [:user_id, :tmdb_id], unique: true
  end
end
