class AddForeignKeyRoleToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :users, :roles, validate: false
  end
end
