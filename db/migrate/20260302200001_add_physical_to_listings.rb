class AddPhysicalToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :physical, :boolean, null: false, default: false
  end
end
