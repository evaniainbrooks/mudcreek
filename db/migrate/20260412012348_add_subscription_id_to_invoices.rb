class AddSubscriptionIdToInvoices < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :invoices, :subscription, null: true, index: { algorithm: :concurrently }
  end
end
