class RenameListingCategorizationsToListingsCategoryAssignments < ActiveRecord::Migration[8.1]
  def change
    safety_assured { rename_table :listing_categorizations, :listings_category_assignments }
  end
end
