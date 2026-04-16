class AddListingToGalleries < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :galleries, :listing, null: true, index: { algorithm: :concurrently }
  end
end
