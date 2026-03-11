class CreateListingsProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_properties do |t|
      t.references :tenant,  null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.string  :name,     null: false
      t.string  :value,    null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :listings_properties, [:listing_id, :position]
  end
end
