class AddAdminNotesToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :admin_notes, :string
  end
end
