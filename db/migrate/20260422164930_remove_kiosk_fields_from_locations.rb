class RemoveKioskFieldsFromLocations < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :locations, :checkin_exit_url,        :string
      remove_column :locations, :background_tint_opacity, :float
      remove_column :locations, :slide_timeout,            :integer
    end
  end
end
