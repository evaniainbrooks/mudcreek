class CreateKiosks < ActiveRecord::Migration[8.1]
  def change
    create_table :kiosks do |t|
      t.references :tenant,   null: false, foreign_key: { on_delete: :cascade }
      t.references :location, null: false, foreign_key: { on_delete: :cascade }
      t.references :schedule, foreign_key: true
      t.string  :checkin_exit_url
      t.float   :background_tint_opacity, default: 0.5, null: false
      t.integer :slide_timeout,           default: 8,   null: false
      t.timestamps
    end
  end
end
