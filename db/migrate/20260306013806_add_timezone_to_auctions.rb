class AddTimezoneToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :timezone, :string, null: false, default: "Eastern Time (US & Canada)"
  end
end
