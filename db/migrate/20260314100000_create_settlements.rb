class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_enum :settlement_line_item_type, %w[hammer_price buyers_premium tax seller_commission seller_fee]

    create_table :settlements do |t|
      t.bigint :lot_id,    null: false
      t.bigint :tenant_id, null: false
      t.timestamps
    end

    add_index :settlements, :lot_id, unique: true
    add_index :settlements, :tenant_id

    create_table :settlement_line_items do |t|
      t.bigint :settlement_id, null: false
      t.bigint :listing_id
      t.bigint :tenant_id, null: false
      t.enum   :line_item_type, null: false, enum_type: :settlement_line_item_type
      t.integer :amount_cents,  null: false
      t.string  :description,   null: false
      t.timestamps
    end

    add_index :settlement_line_items, :settlement_id
    add_index :settlement_line_items, :listing_id
    add_index :settlement_line_items, :tenant_id

    safety_assured do
      add_foreign_key :settlements, :lots,    on_delete: :cascade
      add_foreign_key :settlements, :tenants

      add_foreign_key :settlement_line_items, :settlements, on_delete: :cascade
      add_foreign_key :settlement_line_items, :listings,    on_delete: :nullify
      add_foreign_key :settlement_line_items, :tenants
    end
  end
end
