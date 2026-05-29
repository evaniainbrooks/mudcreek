class AddLocationToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :work_orders, :location, null: false, index: { algorithm: :concurrently }
  end
end
