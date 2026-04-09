class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_enum :ledger_entry_type, %w[credit debit]

    create_table :ledger_entries do |t|
      t.references :tenant,  null: false, foreign_key: true
      t.references :ledger,  null: false, foreign_key: true
      t.references :user,    null: true,  foreign_key: true
      t.string  :description, null: false
      t.enum    :entry_type,  enum_type: :ledger_entry_type, null: false
      t.decimal :amount,      precision: 10, scale: 2
      t.text    :memo
      t.datetime :recorded_at, null: false, default: -> { "NOW()" }

      t.timestamps
    end
  end
end
