class AddUniqueAcceptedOfferIndexToOffers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :offers, :listing_id,
      unique: true,
      where: "state = 'accepted'",
      name: "index_offers_on_listing_id_where_accepted",
      algorithm: :concurrently
  end
end
