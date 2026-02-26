class AddQuantityToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :quantity, :integer, default: 1, null: false
  end
end
