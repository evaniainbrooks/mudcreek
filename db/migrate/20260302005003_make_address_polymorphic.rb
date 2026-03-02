class MakeAddressPolymorphic < ActiveRecord::Migration[8.1]
  def up
    add_column :addresses, :addressable_type, :string
    add_column :addresses, :addressable_id,   :bigint

    safety_assured { execute "UPDATE addresses SET addressable_type = 'User', addressable_id = user_id" }

    safety_assured do
      change_column_null :addresses, :addressable_type, false
      change_column_null :addresses, :addressable_id,   false
    end

    remove_foreign_key :addresses, :users
    remove_index :addresses, name: "index_addresses_on_user_id_and_address_type"
    safety_assured { remove_column :addresses, :user_id }
  end

  def down
    add_column :addresses, :user_id, :bigint

    safety_assured { execute "UPDATE addresses SET user_id = addressable_id WHERE addressable_type = 'User'" }

    change_column_null :addresses, :user_id, false
    add_foreign_key :addresses, :users
    add_index :addresses, [:user_id, :address_type],
      unique: true, name: "index_addresses_on_user_id_and_address_type"

    remove_column :addresses, :addressable_type
    remove_column :addresses, :addressable_id
  end
end
