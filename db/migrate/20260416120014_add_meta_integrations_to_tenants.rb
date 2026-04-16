class AddMetaIntegrationsToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :tenants, :facebook_pixel_id, :string
    add_column :tenants, :facebook_domain_verification, :string
  end
end
