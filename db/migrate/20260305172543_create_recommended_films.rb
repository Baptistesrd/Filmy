class CreateRecommendedFilms < ActiveRecord::Migration[8.1]
  def change
    create_table :recommended_films do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :watch_session, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :year
      t.integer :runtime
      t.text :blurb
      t.boolean :added, null: false, default: false

      t.timestamps
    end

    add_index :recommended_films, [:chat_id, :title, :year], unique: true
  end
end
