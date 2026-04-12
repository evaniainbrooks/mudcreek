class ValidateForeignKeySubscriptionOnInvoices < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :invoices, :subscriptions
  end
end
