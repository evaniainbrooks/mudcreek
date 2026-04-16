class MakeGalleryListingIdUnique < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :galleries, :listing_id,
      name: "index_galleries_on_listing_id",
      algorithm: :concurrently
    add_index :galleries, :listing_id,
      unique: true,
      algorithm: :concurrently
  end
end
