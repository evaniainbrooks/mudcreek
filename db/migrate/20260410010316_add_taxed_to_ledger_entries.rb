class AddTaxedToLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :ledger_entries, :taxed, :boolean, null: false, default: false
  end
end
