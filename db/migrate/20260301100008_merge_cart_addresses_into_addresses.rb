class MergeCartAddressesIntoAddresses < ActiveRecord::Migration[8.1]
  def change
    drop_table :cart_addresses

    add_column :addresses, :address_type, :string, null: false, default: "profile"

    safety_assured do
      remove_index :addresses, :user_id
      add_index :addresses, [ :user_id, :address_type ], unique: true
    end
  end
end
