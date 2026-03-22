class CreateQrScans < ActiveRecord::Migration[8.1]
  def change
    create_table :qr_scans do |t|
      t.references :qr_code, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end
  end
end
