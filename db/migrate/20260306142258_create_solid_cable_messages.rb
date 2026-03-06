class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, null: false
      t.binary :payload, null: false
      t.datetime :created_at, null: false
    end

    add_index :solid_cable_messages, :created_at
  end
end
