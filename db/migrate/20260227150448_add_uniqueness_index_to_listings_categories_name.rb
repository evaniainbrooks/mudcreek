class AddUniquenessIndexToListingsCategoriesName < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :listings_categories, [ :tenant_id, :name ], unique: true, algorithm: :concurrently
  end
end
