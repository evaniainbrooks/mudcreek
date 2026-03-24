class AddSkuToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :sku, :string
  end
end
