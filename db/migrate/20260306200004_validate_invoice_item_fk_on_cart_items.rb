class ValidateInvoiceItemFkOnCartItems < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :cart_items, :invoice_items
  end
end
