class AddRoleToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :users, :role, null: true, index: { algorithm: :concurrently }
  end
end
