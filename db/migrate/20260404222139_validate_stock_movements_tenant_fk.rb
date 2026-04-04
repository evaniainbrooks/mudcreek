class ValidateStockMovementsTenantFk < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :listings_stock_movements, :tenants
  end
end
