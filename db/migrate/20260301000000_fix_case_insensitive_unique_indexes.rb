class FixCaseInsensitiveUniqueIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      # DeliveryMethod: drop redundant tenant_id index (covered by composite)
      remove_index :delivery_methods, name: "index_delivery_methods_on_tenant_id"

      # DeliveryMethod: replace case-sensitive index with lower() expression index
      remove_index :delivery_methods, name: "index_delivery_methods_on_tenant_id_and_name"
      add_index :delivery_methods, "tenant_id, lower(name)",
                name: "index_delivery_methods_on_tenant_id_and_lower_name", unique: true

      # DiscountCode: drop redundant tenant_id index (covered by composite)
      remove_index :discount_codes, name: "index_discount_codes_on_tenant_id"

      # DiscountCode: replace case-sensitive index with lower() expression index
      remove_index :discount_codes, name: "index_discount_codes_on_tenant_id_and_key"
      add_index :discount_codes, "tenant_id, lower(key)",
                name: "index_discount_codes_on_tenant_id_and_lower_key", unique: true
    end
  end
end
