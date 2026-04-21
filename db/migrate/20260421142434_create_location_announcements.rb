class CreateLocationAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :location_announcements do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }
      t.references :location, null: false, foreign_key: { on_delete: :cascade }
      t.references :sent_by,  null: false, foreign_key: { to_table: :users }
      t.string   :subject,        null: false
      t.text     :body,           null: false
      t.datetime :sent_at
      t.integer  :recipient_count
      t.timestamps
    end
  end
end
