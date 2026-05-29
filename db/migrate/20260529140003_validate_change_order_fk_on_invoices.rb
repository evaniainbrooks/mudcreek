class ValidateChangeOrderFkOnInvoices < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :invoices, :change_orders
  end
end
