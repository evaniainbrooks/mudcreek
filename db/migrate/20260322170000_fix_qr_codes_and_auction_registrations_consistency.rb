class FixQrCodesAndAuctionRegistrationsConsistency < ActiveRecord::Migration[8.1]
  def change
    # Redundant: index_qr_codes_on_tenant_id_and_slug already covers tenant_id lookups
    remove_index :qr_codes, name: "index_qr_codes_on_tenant_id"

    safety_assured { add_foreign_key :qr_codes, :users, column: :owner_id }
    safety_assured { add_foreign_key :auction_registrations, :tenants }
  end
end
