class CreateInquiryForms < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiry_forms do |t|
      t.references :tenant,                 null: false, foreign_key: true
      t.references :notification_recipient, null: false, foreign_key: { to_table: :users }
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.text    :description
      t.boolean :published,   null: false, default: false

      t.timestamps
    end

    add_index :inquiry_forms, [ :tenant_id, :slug ], unique: true
  end
end
