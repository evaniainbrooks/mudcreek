class CreateSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :schedules do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }
      t.references :location, null: false, foreign_key: { on_delete: :cascade }
      t.string  :name
      t.string  :source_url
      t.datetime :last_synced_at
      t.timestamps
    end
  end
end
