class AddAdminNotesToAuctionRegistrations < ActiveRecord::Migration[8.1]
  def change
    add_column :auction_registrations, :admin_notes, :text
  end
end
