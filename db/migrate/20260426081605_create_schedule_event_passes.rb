class CreateScheduleEventPasses < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_event_passes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.integer :credits_remaining, null: false
      t.date :expires_at

      t.timestamps
    end
  end
end
