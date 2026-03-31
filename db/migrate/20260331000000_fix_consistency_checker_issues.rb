class FixConsistencyCheckerIssues < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    # Remove redundant single-column index; the unique composite index covers it
    remove_index :listings_deliveries, name: "index_listings_deliveries_on_delivery_method_set_id", if_exists: true

    # Add missing tenant_id index on check_ins
    add_index :check_ins, :tenant_id, algorithm: :concurrently, if_not_exists: true

    # Add missing FK from tenants.default_delivery_method_set_id
    safety_assured do
      add_foreign_key :tenants, :listings_delivery_method_sets,
        column: :default_delivery_method_set_id,
        on_delete: :nullify,
        validate: false
    end
    validate_foreign_key :tenants, :listings_delivery_method_sets
  end

  def down
    remove_foreign_key :tenants, :listings_delivery_method_sets, if_exists: true
    remove_index :check_ins, :tenant_id, if_exists: true
    add_index :listings_deliveries, :delivery_method_set_id,
      name: "index_listings_deliveries_on_delivery_method_set_id"
  end
end
