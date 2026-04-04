class FixStockMovementsTenantFkAndOrderItemIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Replace tenant FK with on_delete: :cascade so deleting a tenant cascades
    remove_foreign_key :listings_stock_movements, :tenants
    add_foreign_key :listings_stock_movements, :tenants, on_delete: :cascade, validate: false

    # has_one :stock_movement on OrderItem requires a unique index on order_item_id
    remove_index :listings_stock_movements, :order_item_id
    add_index :listings_stock_movements, :order_item_id, unique: true, algorithm: :concurrently
  end
end
