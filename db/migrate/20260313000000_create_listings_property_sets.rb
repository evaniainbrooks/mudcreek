class CreateListingsPropertySets < ActiveRecord::Migration[8.1]
  def change
    create_table :listings_property_sets do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
