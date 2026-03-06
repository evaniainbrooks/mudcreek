class CreateInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :invoice_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.references :listing, null: true, foreign_key: true
      t.string :name, null: false
      t.integer :amount_cents, null: false
      t.timestamps
    end
  end
end
