class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :film, null: false, foreign_key: true
      t.integer :score, null: false
      t.text :review

      t.timestamps
    end

    add_index :ratings, [:user_id, :film_id], unique: true
  end
end
