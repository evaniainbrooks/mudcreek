class CreateScheduleEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :schedule_events do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }
      t.references :schedule, null: false, foreign_key: { on_delete: :cascade }
      t.string  :uid,         null: false
      t.string  :summary
      t.text    :description
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :all_day,     default: false, null: false
      t.string  :rrule
      t.timestamps
    end

    add_index :schedule_events, [:schedule_id, :uid], unique: true
  end
end
