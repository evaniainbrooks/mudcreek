class AddGuestFieldsToOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :orders, :user_id, true
    add_column :orders, :guest_email, :string
    add_column :orders, :guest_name, :string
    add_column :orders, :guest_token, :string
    add_index :orders, :guest_token, unique: true, algorithm: :concurrently
  end
end
