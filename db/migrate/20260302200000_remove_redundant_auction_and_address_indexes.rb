class RemoveRedundantAuctionAndAddressIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # index_auction_registrations_on_auction_id_and_user_id (unique composite) already
    # covers lookups by auction_id alone, so the single-column index is redundant.
    remove_index :auction_registrations, :auction_id,
      name: "index_auction_registrations_on_auction_id",
      algorithm: :concurrently

    # index_addresses_on_addressable_and_type (unique composite on type+id+address_type)
    # covers lookups by type+id alone, so the two-column index is redundant.
    remove_index :addresses,
      name: "index_addresses_on_addressable",
      algorithm: :concurrently
  end
end
