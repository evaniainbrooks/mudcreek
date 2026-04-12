class AddForeignKeySubscriptionToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :invoices, :subscriptions, validate: false
  end
end
