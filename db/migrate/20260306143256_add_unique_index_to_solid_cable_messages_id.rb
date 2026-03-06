class AddUniqueIndexToSolidCableMessagesId < ActiveRecord::Migration[8.1]
  def change
    add_index :solid_cable_messages, :id, unique: true, if_not_exists: true
    add_index :solid_cable_messages, :created_at, if_not_exists: true
  end
end
