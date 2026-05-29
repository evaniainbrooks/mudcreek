class AddDropboxSignRequestIdIndexToChangeOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :change_orders, :dropbox_sign_request_id, algorithm: :concurrently
  end
end
