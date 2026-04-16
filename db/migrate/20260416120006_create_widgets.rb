class CreateWidgets < ActiveRecord::Migration[8.0]
  def change
    create_table :widgets do |t|
      t.string     :type,           null: false
      t.references :page,           null: false, foreign_key: { on_delete: :cascade }, index: true
      t.integer    :position,       null: false, default: 0
      t.bigint     :gallery_id
      t.bigint     :location_id
      t.bigint     :inquiry_form_id
      t.bigint     :qr_code_id
      t.bigint     :tenant_id,      null: false
      t.timestamps
    end

    add_index :widgets, :tenant_id
    add_index :widgets, :gallery_id
    add_index :widgets, :location_id
    add_index :widgets, :inquiry_form_id
    add_index :widgets, :qr_code_id

    add_foreign_key :widgets, :galleries,     column: :gallery_id,      on_delete: :cascade, validate: false
    add_foreign_key :widgets, :locations,     column: :location_id,     on_delete: :cascade, validate: false
    add_foreign_key :widgets, :inquiry_forms, column: :inquiry_form_id, on_delete: :cascade, validate: false
    add_foreign_key :widgets, :qr_codes,      column: :qr_code_id,      on_delete: :cascade, validate: false
    add_foreign_key :widgets, :tenants,       column: :tenant_id,       on_delete: :cascade, validate: false
  end
end
