class AddSlideTimeoutToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :slide_timeout, :integer, default: 8, null: false
  end
end
