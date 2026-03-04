class AddUserReferenceToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :user, foreign_key: true, null: false
  end
end
