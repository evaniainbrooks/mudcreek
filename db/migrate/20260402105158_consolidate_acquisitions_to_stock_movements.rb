class ConsolidateAcquisitionsToStockMovements < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      rename_table  :listings_acquisitions,    :listings_stock_movements
      rename_column :listings_stock_movements, :acquired_on, :transacted_on
    end
    add_column :listings_stock_movements, :kind,   :string, null: false, default: "in"
    add_column :listings_stock_movements, :reason, :string, null: false, default: "acquisition"
    add_reference :listings_stock_movements, :order_item, null: true, index: { algorithm: :concurrently }
    safety_assured { add_foreign_key :listings_stock_movements, :order_items }
  end
end
