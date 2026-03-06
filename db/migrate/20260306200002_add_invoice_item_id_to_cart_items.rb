class AddInvoiceItemIdToCartItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :cart_items, :invoice_item, null: true, index: { algorithm: :concurrently }
  end
end
