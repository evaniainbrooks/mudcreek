class AddInvoiceItemFkToCartItems < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :cart_items, :invoice_items, validate: false
  end
end
