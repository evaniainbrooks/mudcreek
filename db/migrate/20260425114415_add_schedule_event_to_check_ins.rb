class AddScheduleEventToCheckIns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :check_ins, :schedule_event, null: true, index: { algorithm: :concurrently }
    add_foreign_key :check_ins, :schedule_events, validate: false
  end
end
