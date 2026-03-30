class CreateListingsDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_deliveries do |t|
      t.references :tenant, null: false, foreign_key: { on_delete: :cascade }
      t.references :delivery_method_set, null: false, foreign_key: { to_table: :listings_delivery_method_sets, on_delete: :cascade }
      t.references :delivery_method, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :listings_deliveries, %i[delivery_method_set_id delivery_method_id], unique: true, name: "index_listings_deliveries_unique"
  end
end
