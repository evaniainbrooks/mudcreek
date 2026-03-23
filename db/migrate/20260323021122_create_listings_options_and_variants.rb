class CreateListingsOptionsAndVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_options do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :tenant,  null: false, foreign_key: true
      t.string  :name,     null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :listings_option_values do |t|
      t.references :option, null: false, foreign_key: { to_table: :listings_options }
      t.string  :value,    null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :listings_variants do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :tenant,  null: false, foreign_key: true
      t.integer :price_cents
      t.integer :quantity, null: false, default: 0
      t.string  :sku
      t.timestamps
    end

    create_table :listings_variant_option_values do |t|
      t.references :variant,      null: false, foreign_key: { to_table: :listings_variants }
      t.references :option_value, null: false, foreign_key: { to_table: :listings_option_values }
      t.index [:variant_id, :option_value_id], unique: true
    end
  end
end
