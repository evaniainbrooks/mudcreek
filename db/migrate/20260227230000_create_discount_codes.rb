class CreateDiscountCodes < ActiveRecord::Migration[8.1]
  def change
    create_enum :discount_code_type, %w[fixed percentage]

    create_table :discount_codes do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :key, null: false
      t.enum :discount_type, enum_type: :discount_code_type, null: false
      t.integer :amount_cents, null: false
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end

    add_index :discount_codes, [ :tenant_id, :key ], unique: true
    add_check_constraint :discount_codes, "amount_cents > 0",
      name: "discount_codes_amount_cents_positive", validate: false
  end
end
