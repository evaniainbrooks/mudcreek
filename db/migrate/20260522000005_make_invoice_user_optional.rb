class MakeInvoiceUserOptional < ActiveRecord::Migration[8.1]
  def change
    safety_assured { change_column_null :invoices, :user_id, true }
  end
end
