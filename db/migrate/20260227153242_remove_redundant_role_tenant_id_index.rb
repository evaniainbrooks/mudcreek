class RemoveRedundantRoleTenantIdIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :roles, name: "index_roles_on_tenant_id"
  end
end
