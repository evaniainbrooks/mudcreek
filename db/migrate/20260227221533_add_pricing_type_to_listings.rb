class AddPricingTypeToListings < ActiveRecord::Migration[8.1]
  def change
    create_enum :listing_pricing_type, %w[firm negotiable]
    add_column :listings, :pricing_type, :enum, enum_type: :listing_pricing_type, default: "firm", null: false
  end
end
