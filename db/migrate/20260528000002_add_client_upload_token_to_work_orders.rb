class AddClientUploadTokenToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :work_orders, :client_upload_token, :string
    add_index  :work_orders, :client_upload_token, unique: true, algorithm: :concurrently
  end
end
