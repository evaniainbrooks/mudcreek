class AddAdminNotesToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :admin_notes, :text unless column_exists?(:invoices, :admin_notes)
  end
end
