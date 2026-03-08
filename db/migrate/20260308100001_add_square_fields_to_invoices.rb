class AddSquareFieldsToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :square_payment_id, :string
    add_column :invoices, :charge_error, :text
  end
end
