class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.bigint  :tenant_id, null: false
      t.bigint  :user_id,   null: false
      t.string  :number,    null: false
      t.string  :status,    null: false, default: "pending"

      # Delivery snapshot
      t.bigint  :delivery_method_id                        # nullable FK
      t.string  :delivery_method_name
      t.integer :delivery_price_cents, null: false, default: 0

      # Address snapshot
      t.string :street_address
      t.string :city
      t.string :province
      t.string :postal_code
      t.string :country

      # Discount snapshot
      t.bigint  :discount_code_id                          # nullable FK
      t.string  :discount_code_key
      t.integer :discount_cents, null: false, default: 0

      # Totals
      t.integer :subtotal_cents, null: false
      t.integer :tax_cents,      null: false
      t.integer :total_cents,    null: false

      t.timestamps

      t.index :tenant_id
      t.index :user_id
      t.index :number, unique: true
    end

    safety_assured do
      add_foreign_key :orders, :users
      add_foreign_key :orders, :tenants
    end
  end
end
