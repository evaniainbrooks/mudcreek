class CreateScheduleEventSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_event_sessions do |t|
      t.references :schedule_event, null: false, foreign_key: true
      t.date :occurs_on, null: false
      t.references :tenant, null: false, foreign_key: true

      t.timestamps
    end

    add_index :schedule_event_sessions, [:schedule_event_id, :occurs_on], unique: true
  end
end
