class ReplaceEmailAddressIndexWithLowerExpression < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    opts = connection.adapter_name == "PostgreSQL" ? { algorithm: :concurrently } : {}

    remove_index :users, :email_address, if_exists: true, **opts
    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address", **opts
  end
end
