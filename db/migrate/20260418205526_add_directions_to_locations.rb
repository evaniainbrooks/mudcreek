class AddDirectionsToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :directions, :text
  end
end
