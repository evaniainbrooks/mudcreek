class CreateListingCategorizations < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_categorizations do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :listings_category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :listing_categorizations, [ :listing_id, :listings_category_id ], unique: true
  end
end
