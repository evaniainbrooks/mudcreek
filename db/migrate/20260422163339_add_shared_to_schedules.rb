class AddSharedToSchedules < ActiveRecord::Migration[8.1]
  def change
    add_column :schedules, :shared, :boolean, default: false, null: false
  end
end
