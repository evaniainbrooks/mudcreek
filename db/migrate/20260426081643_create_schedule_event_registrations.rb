class CreateScheduleEventRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_event_registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :schedule_event_session, null: false, foreign_key: true
      t.references :schedule_event_pass, null: true, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :schedule_event_registrations, [:user_id, :schedule_event_session_id],
              unique: true,
              where: "status != 1",
              name: "index_ser_on_user_and_session_not_cancelled"
  end
end
