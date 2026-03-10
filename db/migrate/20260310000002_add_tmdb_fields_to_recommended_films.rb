class AddTmdbFieldsToRecommendedFilms < ActiveRecord::Migration[8.1]
  def change
    add_column :recommended_films, :tmdb_id, :integer
    add_column :recommended_films, :poster_url, :string
    add_column :recommended_films, :genre, :string
    add_column :recommended_films, :rating, :decimal, precision: 3, scale: 1
    add_column :recommended_films, :director, :string
    add_column :recommended_films, :cast_members, :string
    add_column :recommended_films, :trailer_url, :string

    add_index :recommended_films, :tmdb_id
  end
end
