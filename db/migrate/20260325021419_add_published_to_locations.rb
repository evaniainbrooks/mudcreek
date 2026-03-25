class AddPublishedToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :published, :boolean, default: false, null: false
  end
end
