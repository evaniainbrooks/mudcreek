class MakeAuctionTimingFieldsNotNull < ActiveRecord::Migration[8.1]
  def up
    change_column_default :auctions, :end_time_stagger_interval, 0
    change_column_default :auctions, :bidding_extension, 0
    Auction.unscoped.where(end_time_stagger_interval: nil).update_all(end_time_stagger_interval: 0)
    Auction.unscoped.where(bidding_extension: nil).update_all(bidding_extension: 0)
    safety_assured do
      change_column_null :auctions, :end_time_stagger_interval, false
      change_column_null :auctions, :bidding_extension, false
    end
  end

  def down
    change_column_null :auctions, :end_time_stagger_interval, true
    change_column_null :auctions, :bidding_extension, true
    change_column_default :auctions, :end_time_stagger_interval, nil
    change_column_default :auctions, :bidding_extension, nil
  end
end
