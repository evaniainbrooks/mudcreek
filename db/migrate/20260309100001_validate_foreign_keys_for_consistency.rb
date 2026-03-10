class ValidateForeignKeysForConsistency < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :bid_increment_schedules, :tenants
    validate_foreign_key :bid_increment_schedules, :auctions
    validate_foreign_key :bid_increment_tiers, :bid_increment_schedules
    validate_foreign_key :invoices, :offers
  end
end
