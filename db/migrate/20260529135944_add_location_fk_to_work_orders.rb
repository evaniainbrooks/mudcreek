class AddLocationFkToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :work_orders, :locations, validate: false
    validate_foreign_key :work_orders, :locations
  end
end
