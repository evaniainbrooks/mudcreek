class AddBuyersPremiumRateToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :buyers_premium_rate, :integer, default: 0, null: false
  end
end
