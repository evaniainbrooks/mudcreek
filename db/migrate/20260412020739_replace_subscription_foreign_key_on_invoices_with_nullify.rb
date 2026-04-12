class ReplaceSubscriptionForeignKeyOnInvoicesWithNullify < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :invoices, :subscriptions
    add_foreign_key :invoices, :subscriptions, on_delete: :nullify, validate: false
  end
end
