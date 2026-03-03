class AddBiddingExtensionToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :bidding_extension, :integer
  end
end
