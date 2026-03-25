class AddCheckinExitUrlToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :checkin_exit_url, :string
  end
end
