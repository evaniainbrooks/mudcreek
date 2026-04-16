class ChangeGalleriesListingForeignKeyToCascade < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :galleries, :listings
    add_foreign_key :galleries, :listings, on_delete: :cascade, validate: false
  end
end
