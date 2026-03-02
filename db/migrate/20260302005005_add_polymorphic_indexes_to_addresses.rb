class AddPolymorphicIndexesToAddresses < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :addresses, [:addressable_type, :addressable_id],
      name: "index_addresses_on_addressable", algorithm: :concurrently
    add_index :addresses, [:addressable_type, :addressable_id, :address_type],
      name: "index_addresses_on_addressable_and_type", unique: true, algorithm: :concurrently
  end
end
