class CreateFilms < ActiveRecord::Migration[8.1]
  def change
    create_table :films do |t|
      t.string :title
      t.string :genre
      t.references :watch_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
