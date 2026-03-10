class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recommended_film, null: false, foreign_key: true
      t.string :rating_type, null: false

      t.timestamps
    end

    add_index :feedbacks, [:user_id, :recommended_film_id], unique: true
  end
end
