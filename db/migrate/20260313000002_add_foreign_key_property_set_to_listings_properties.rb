class AddForeignKeyPropertySetToListingsProperties < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :listings_properties, :listings_property_sets,
      column: :property_set_id,
      validate: false
  end
end
