class RemoveRedundantTenantIndexFromEmailAliases < ActiveRecord::Migration[8.1]
  def change
    remove_index :email_aliases, :tenant_id
  end
end
