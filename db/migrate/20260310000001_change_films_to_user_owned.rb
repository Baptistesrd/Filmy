class ChangeFilmsToUserOwned < ActiveRecord::Migration[8.1]
  def change
    # Safe: 0 film records exist
    remove_foreign_key :films, :watch_sessions
    remove_index :films, :watch_session_id
    remove_column :films, :watch_session_id, :bigint

    add_reference :films, :user, null: false, foreign_key: true

    add_column :films, :tmdb_id, :integer
    add_column :films, :synopsis, :text
    add_column :films, :director, :string
    add_column :films, :cast_members, :string
    add_column :films, :trailer_url, :string
    add_column :films, :rating, :decimal, precision: 3, scale: 1
    add_column :films, :blurb, :text

    add_index :films, :tmdb_id
    add_index :films, [:user_id, :tmdb_id], unique: true, where: "tmdb_id IS NOT NULL"
  end
end
