class AddTaxRateToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :tax_rate, :decimal, precision: 8, scale: 4, null: false, default: SALES_TAX_RATE
  end
end
