class FixConsistencyCheckers < ActiveRecord::Migration[8.1]
  def change
    # RedundantIndexChecker: the composite unique index on (variant_id, option_value_id)
    # already covers variant_id-only lookups, so the auto-generated single-column index is redundant.
    remove_index :listings_variant_option_values, name: "index_listings_variant_option_values_on_variant_id"

    # MissingDependentDestroyChecker: tenant FK on listings_options and listings_variants
    # must cascade so deleting a tenant cleans up its options/variants.
    remove_foreign_key :listings_options,  column: :tenant_id
    remove_foreign_key :listings_variants, column: :tenant_id
    safety_assured do
      add_foreign_key :listings_options,  :tenants, column: :tenant_id, on_delete: :cascade
      add_foreign_key :listings_variants, :tenants, column: :tenant_id, on_delete: :cascade
    end

    # ForeignKeyCascadeChecker: qr_codes.owner_id FK needs on_delete: :nullify
    # so deleting a user doesn't orphan their QR codes.
    remove_foreign_key :qr_codes, column: :owner_id
    safety_assured do
      add_foreign_key :qr_codes, :users, column: :owner_id, on_delete: :nullify
    end
  end
end
