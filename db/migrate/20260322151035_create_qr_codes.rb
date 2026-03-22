class CreateQrCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_codes do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string   :name,            null: false
      t.string   :slug,            null: false
      t.text     :destination_url, null: false
      t.text     :inactive_url
      t.text     :notes
      t.boolean  :active,          null: false, default: true
      t.datetime :expires_at
      t.integer  :scan_count,      null: false, default: 0
      t.datetime :last_scanned_at
      t.timestamps
    end
    add_index :qr_codes, [:tenant_id, :slug], unique: true
  end
end
