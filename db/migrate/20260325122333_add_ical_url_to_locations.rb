class AddIcalUrlToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :ical_url, :string
  end
end
