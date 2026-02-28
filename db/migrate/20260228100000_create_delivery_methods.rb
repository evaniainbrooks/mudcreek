class CreateDeliveryMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_methods do |t|
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end

    add_check_constraint :delivery_methods, "price_cents >= 0", name: "delivery_methods_price_cents_non_negative"
    add_index :delivery_methods, [:tenant_id, :name], unique: true
  end
end
