class RemoveRedundantListingIdIndexFromListingsCategoryAssignments < ActiveRecord::Migration[8.1]
  def change
    remove_index :listings_category_assignments, name: "index_listings_category_assignments_on_listing_id"
  end
end
