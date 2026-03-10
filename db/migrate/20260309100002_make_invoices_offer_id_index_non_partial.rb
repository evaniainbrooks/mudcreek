class MakeInvoicesOfferIdIndexNonPartial < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Replace the partial unique index (WHERE offer_id IS NOT NULL) with a full
  # unique index. PostgreSQL treats NULLs as distinct in unique indexes, so
  # multiple NULL offer_ids are still allowed. A non-partial index is required
  # for database_consistency to recognise the matching validates :offer_id,
  # uniqueness: true, allow_nil: true validator.
  def change
    remove_index :invoices, name: :index_invoices_on_offer_id_unique, algorithm: :concurrently
    add_index :invoices, :offer_id, unique: true, name: :index_invoices_on_offer_id_unique, algorithm: :concurrently
  end
end
