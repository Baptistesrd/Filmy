class AddYearToFilms < ActiveRecord::Migration[8.1]
  def change
    add_column :films, :year, :integer
  end
end
