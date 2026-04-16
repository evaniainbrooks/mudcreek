class AddListingForeignKeyToGalleries < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :galleries, :listings, on_delete: :nullify, validate: false
  end
end
