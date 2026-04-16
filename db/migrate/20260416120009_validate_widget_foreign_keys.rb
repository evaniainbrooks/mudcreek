class ValidateWidgetForeignKeys < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :widgets, :galleries,     column: :gallery_id
    validate_foreign_key :widgets, :locations,     column: :location_id
    validate_foreign_key :widgets, :inquiry_forms, column: :inquiry_form_id
    validate_foreign_key :widgets, :qr_codes,      column: :qr_code_id
    validate_foreign_key :widgets, :tenants,       column: :tenant_id
  end
end
