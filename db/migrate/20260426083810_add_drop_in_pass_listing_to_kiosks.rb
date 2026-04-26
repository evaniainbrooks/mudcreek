class AddDropInPassListingToKiosks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :kiosks, :drop_in_pass_listing, null: true, index: { algorithm: :concurrently }
    add_foreign_key :kiosks, :listings, column: :drop_in_pass_listing_id, validate: false
  end
end
