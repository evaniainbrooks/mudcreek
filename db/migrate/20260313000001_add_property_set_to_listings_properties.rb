class AddPropertySetToListingsProperties < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :listings_properties, :property_set, null: true, index: { algorithm: :concurrently }
  end
end
