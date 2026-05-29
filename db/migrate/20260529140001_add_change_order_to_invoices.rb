class AddChangeOrderToInvoices < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :invoices, :change_order, null: true, index: { algorithm: :concurrently }
  end
end
