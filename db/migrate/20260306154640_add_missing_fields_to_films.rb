class AddMissingFieldsToFilms < ActiveRecord::Migration[8.1]
  def change
    add_column :films, :runtime, :integer
    add_column :films, :streaming_services, :string
    add_column :films, :justwatch_url, :string
  end
end
