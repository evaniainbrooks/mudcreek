class ValidateWorkOrderMilestoneFkOnInvoices < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :invoices, :work_order_milestones
  end
end
