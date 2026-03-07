class AddOfferToInvoices < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :invoices, :auction_id, true
    add_reference :invoices, :offer, null: true, index: { algorithm: :concurrently }
  end
end
