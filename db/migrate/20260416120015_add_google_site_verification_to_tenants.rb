class AddGoogleSiteVerificationToTenants < ActiveRecord::Migration[8.0]
  def change
    add_column :tenants, :google_site_verification, :string
  end
end
