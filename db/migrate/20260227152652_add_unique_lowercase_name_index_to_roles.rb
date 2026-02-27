class AddUniqueLowercaseNameIndexToRoles < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<~SQL
        CREATE UNIQUE INDEX CONCURRENTLY index_roles_on_tenant_id_and_lower_name
        ON roles (tenant_id, lower(name))
      SQL
    end
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_roles_on_tenant_id_and_lower_name"
  end
end
