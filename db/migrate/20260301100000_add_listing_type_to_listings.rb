class AddListingTypeToListings < ActiveRecord::Migration[8.1]
  def change
    create_enum :listing_type, %w[sale rental]
    safety_assured do
      add_column :listings, :listing_type, :enum,
        enum_type: :listing_type, default: "sale", null: false
    end
  end
end
