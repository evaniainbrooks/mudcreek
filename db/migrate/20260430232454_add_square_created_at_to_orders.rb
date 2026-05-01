class AddSquareCreatedAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :square_created_at, :datetime
  end
end
