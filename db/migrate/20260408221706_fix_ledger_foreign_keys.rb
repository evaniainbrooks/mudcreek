class FixLedgerForeignKeys < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :ledgers,       :tenants
    add_foreign_key    :ledgers,       :tenants, on_delete: :cascade, validate: false

    remove_foreign_key :ledger_entries, :tenants
    add_foreign_key    :ledger_entries, :tenants, on_delete: :cascade,  validate: false

    remove_foreign_key :ledger_entries, :users
    add_foreign_key    :ledger_entries, :users,   on_delete: :nullify, validate: false
  end
end
