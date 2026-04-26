class AddBookableToScheduleEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :schedule_events, :bookable, :boolean, default: false, null: false
  end
end
