class AddPosterUrlToFilms < ActiveRecord::Migration[8.1]
  def change
    add_column :films, :poster_url, :string
  end
end
