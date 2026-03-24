class AddVariantToAuctionListings < ActiveRecord::Migration[8.0]
  def change
    add_column :auction_listings, :variant_id, :bigint

    remove_index :auction_listings, :listing_id

    add_index :auction_listings, :listing_id,
      unique: true,
      where: "variant_id IS NULL",
      name: "index_auction_listings_on_listing_id_no_variant"

    add_index :auction_listings, [:listing_id, :variant_id],
      unique: true,
      where: "variant_id IS NOT NULL",
      name: "index_auction_listings_on_listing_id_and_variant_id"

    add_foreign_key :auction_listings, :listings_variants, column: :variant_id, on_delete: :cascade
  end
end
