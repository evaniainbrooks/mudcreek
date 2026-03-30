class AddDeliveryMethodSetToListings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :listings, :delivery_method_set, null: true, index: false

    add_index :listings, :delivery_method_set_id, algorithm: :concurrently

    safety_assured do
      add_foreign_key :listings, :listings_delivery_method_sets,
        column: :delivery_method_set_id, on_delete: :nullify, validate: false
    end
  end
end
