class MakeImprovmxDomainTenantIdUnique < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :improvmx_domains, :tenant_id,
      name: "index_improvmx_domains_on_tenant_id",
      algorithm: :concurrently
    add_index :improvmx_domains, :tenant_id,
      unique: true,
      algorithm: :concurrently
  end
end
