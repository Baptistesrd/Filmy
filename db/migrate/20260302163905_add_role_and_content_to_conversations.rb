class AddRoleAndContentToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :role, :string
    add_column :conversations, :content, :text
  end
end
