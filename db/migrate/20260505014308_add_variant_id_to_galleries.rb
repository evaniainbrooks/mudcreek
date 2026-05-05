class AddVariantIdToGalleries < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :galleries, :variant, null: true, index: { algorithm: :concurrently }
    add_foreign_key :galleries, :listings_variants, column: :variant_id, validate: false
  end
end
