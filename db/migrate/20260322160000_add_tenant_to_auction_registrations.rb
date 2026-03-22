class AddTenantToAuctionRegistrations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_reference :auction_registrations, :tenant, null: true, index: { algorithm: :concurrently }

    AuctionRegistration.unscoped
                       .joins(:auction)
                       .update_all("tenant_id = auctions.tenant_id")

    safety_assured { change_column_null :auction_registrations, :tenant_id, false }
  end

  def down
    remove_reference :auction_registrations, :tenant
  end
end
