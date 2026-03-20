class RemoveRedundantProxyBidsListingIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :proxy_bids, name: "index_proxy_bids_on_auction_listing_id"
  end
end
