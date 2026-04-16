class ValidateListingForeignKeyOnWidgets < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :widgets, :listings, column: :listing_id
  end
end
