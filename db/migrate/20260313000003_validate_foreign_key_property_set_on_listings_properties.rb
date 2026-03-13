class ValidateForeignKeyPropertySetOnListingsProperties < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :listings_properties, :listings_property_sets, column: :property_set_id
  end
end
