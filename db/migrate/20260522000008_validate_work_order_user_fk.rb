class ValidateWorkOrderUserFk < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :work_orders, :users
  end
end
