class FixWorkOrderIndexesAndUserFk < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Remove indexes redundant because composite indexes already cover them
    remove_index :work_order_milestones, :work_order_id,
      name: "index_work_order_milestones_on_work_order_id", if_exists: true
    remove_index :work_orders, :tenant_id,
      name: "index_work_orders_on_tenant_id", if_exists: true

    # Swap work_orders.user_id FK to nullify on user deletion
    remove_foreign_key :work_orders, :users
    add_foreign_key :work_orders, :users, on_delete: :nullify, validate: false

    # Add missing index for find_by lookup in HandleDropboxSignEventJob
    add_index :work_orders, :dropbox_sign_request_id,
      name: "index_work_orders_on_dropbox_sign_request_id",
      algorithm: :concurrently,
      if_not_exists: true
  end

  def down
    remove_index :work_orders, :dropbox_sign_request_id,
      name: "index_work_orders_on_dropbox_sign_request_id", if_exists: true

    remove_foreign_key :work_orders, :users
    add_foreign_key :work_orders, :users

    add_index :work_orders, :tenant_id,
      name: "index_work_orders_on_tenant_id", algorithm: :concurrently, if_not_exists: true
    add_index :work_order_milestones, :work_order_id,
      name: "index_work_order_milestones_on_work_order_id", algorithm: :concurrently, if_not_exists: true
  end
end
