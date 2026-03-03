class AddSucceededOrderIndexToTransactions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :transactions, :order_id,
              unique: true,
              where: "state = 'succeeded'",
              name: "index_transactions_on_order_id_succeeded",
              algorithm: :concurrently
  end
end
