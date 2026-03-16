class RemoveRedundantSingleColumnIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :listings_properties,    name: "index_listings_properties_on_listing_id"
    remove_index :social_media_accounts,  name: "index_social_media_accounts_on_tenant_id"
  end
end
