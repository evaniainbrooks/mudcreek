class AddIconToListingsProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :listings_properties, :icon, :string
  end
end
