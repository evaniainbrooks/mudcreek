class AddCapacityToScheduleEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :schedule_events, :capacity, :integer
  end
end
