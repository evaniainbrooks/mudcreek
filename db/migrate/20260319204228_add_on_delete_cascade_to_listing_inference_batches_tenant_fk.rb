class AddOnDeleteCascadeToListingInferenceBatchesTenantFk < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_foreign_key :listing_inference_batches, :tenants
    add_foreign_key :listing_inference_batches, :tenants, on_delete: :cascade, validate: false
    validate_foreign_key :listing_inference_batches, :tenants
  end
end
