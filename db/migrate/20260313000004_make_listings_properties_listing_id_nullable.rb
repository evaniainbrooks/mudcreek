class MakeListingsPropertiesListingIdNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :listings_properties, :listing_id, true
  end
end
