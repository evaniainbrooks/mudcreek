class AddConcurrentIndexesToOrdersAndOrderItems < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :orders, :delivery_method_id, algorithm: :concurrently
    add_index :orders, :discount_code_id, algorithm: :concurrently
    add_index :order_items, :listing_id, algorithm: :concurrently
  end
end
