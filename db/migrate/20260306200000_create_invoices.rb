class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_enum :invoice_status, %w[unpaid paid]

    create_table :invoices do |t|
      t.string :number, null: false
      t.references :user, null: false, foreign_key: true
      t.references :auction, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.integer :total_cents, null: false
      t.enum :status, enum_type: :invoice_status, null: false, default: "unpaid"
      t.timestamps
    end

    add_index :invoices, :number, unique: true
  end
end
