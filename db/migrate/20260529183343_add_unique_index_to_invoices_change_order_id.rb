class AddUniqueIndexToInvoicesChangeOrderId < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :invoices, :change_order_id, algorithm: :concurrently
    add_index :invoices, :change_order_id, unique: true, algorithm: :concurrently
  end
end
