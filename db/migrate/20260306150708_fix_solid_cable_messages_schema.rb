class FixSolidCableMessagesSchema < ActiveRecord::Migration[8.1]
  def change
    add_column :solid_cable_messages, :channel_hash, :bigint, null: false, default: 0 unless column_exists?(:solid_cable_messages, :channel_hash)

    change_column :solid_cable_messages, :channel, :binary, limit: 1024, null: false
    change_column :solid_cable_messages, :payload, :binary, limit: 536_870_912, null: false

    add_index :solid_cable_messages, :channel, if_not_exists: true
    add_index :solid_cable_messages, :channel_hash, if_not_exists: true
    add_index :solid_cable_messages, :created_at, if_not_exists: true
  end
end
