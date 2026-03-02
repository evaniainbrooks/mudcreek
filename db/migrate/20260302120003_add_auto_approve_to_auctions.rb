class AddAutoApproveToAuctions < ActiveRecord::Migration[8.1]
  def change
    add_column :auctions, :auto_approve, :boolean, null: false, default: false
  end
end
