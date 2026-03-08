class AddQuantityToCartItems < ActiveRecord::Migration[8.1]
  def change
    add_column :cart_items, :quantity, :integer, default: 1, null: false
  end
end
