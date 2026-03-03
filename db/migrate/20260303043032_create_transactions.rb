class CreateTransactions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_enum :transaction_state, %w[pending succeeded failed]

    create_table :transactions do |t|
      t.references :order, null: false, foreign_key: true
      t.uuid :uuid, null: false
      t.enum :state, enum_type: :transaction_state, default: "pending", null: false
      t.integer :amount_cents, null: false
      t.string :square_payment_id
      t.text :error_message
      t.jsonb :raw_response
      t.timestamps
    end

    add_index :transactions, :uuid, unique: true, algorithm: :concurrently
  end
end
