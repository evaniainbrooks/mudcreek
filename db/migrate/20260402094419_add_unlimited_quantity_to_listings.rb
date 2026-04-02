class AddUnlimitedQuantityToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :unlimited_quantity, :boolean, default: false, null: false
  end
end
