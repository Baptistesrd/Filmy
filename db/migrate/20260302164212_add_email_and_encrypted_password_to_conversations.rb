class AddEmailAndEncryptedPasswordToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :email, :string
    add_column :conversations, :encrypted_password, :string
  end
end
