class ValidateListingForeignKeyOnGalleries < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :galleries, :listings
  end
end
