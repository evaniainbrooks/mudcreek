class AddOnDeleteToTenantAndDeliveryMethodFks < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # listings_properties → tenants
    remove_foreign_key :listings_properties, :tenants
    add_foreign_key    :listings_properties, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :listings_properties, :tenants

    if table_exists?(:listings_deliveries)
      # listings_deliveries → tenants
      remove_foreign_key :listings_deliveries, :tenants, if_exists: true
      add_foreign_key    :listings_deliveries, :tenants, on_delete: :cascade, validate: false
      validate_foreign_key :listings_deliveries, :tenants

      # listings_deliveries → delivery_methods
      remove_foreign_key :listings_deliveries, :delivery_methods, if_exists: true
      add_foreign_key    :listings_deliveries, :delivery_methods, on_delete: :cascade, validate: false
      validate_foreign_key :listings_deliveries, :delivery_methods
    end

    # settlement_line_items → tenants
    remove_foreign_key :settlement_line_items, :tenants
    add_foreign_key    :settlement_line_items, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :settlement_line_items, :tenants

    # settlements → tenants
    remove_foreign_key :settlements, :tenants
    add_foreign_key    :settlements, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :settlements, :tenants
  end
end
