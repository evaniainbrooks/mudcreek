class AddChangeOrderFkToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :invoices, :change_orders, on_delete: :nullify, validate: false
  end
end
