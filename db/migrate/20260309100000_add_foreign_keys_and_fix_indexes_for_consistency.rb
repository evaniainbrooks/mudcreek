class AddForeignKeysAndFixIndexesForConsistency < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Foreign keys missing from bid_increment_schedules and bid_increment_tiers
    add_foreign_key :bid_increment_schedules, :tenants, validate: false
    add_foreign_key :bid_increment_schedules, :auctions, on_delete: :cascade, validate: false
    add_foreign_key :bid_increment_tiers, :bid_increment_schedules, on_delete: :cascade, validate: false

    # Foreign key missing from invoices for offer_id
    add_foreign_key :invoices, :offers, on_delete: :nullify, validate: false

    # Make invoices.offer_id unique — Offer has_one :invoice requires a unique index
    remove_index :invoices, name: :index_invoices_on_offer_id, algorithm: :concurrently
    add_index :invoices, :offer_id,
              unique: true,
              where: "offer_id IS NOT NULL",
              name: :index_invoices_on_offer_id_unique,
              algorithm: :concurrently

    # Index for DiscountCode.find_by(key:)
    add_index :discount_codes, :key, algorithm: :concurrently

    # Index for User.find_by(email_address:)
    add_index :users, :email_address, algorithm: :concurrently
  end
end
