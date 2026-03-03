class AddSquarePaymentIdToOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :orders, :square_payment_id, :string
    add_index  :orders, :square_payment_id, unique: true, algorithm: :concurrently
  end
end
