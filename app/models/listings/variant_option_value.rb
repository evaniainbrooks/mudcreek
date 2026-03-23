class Listings::VariantOptionValue < ApplicationRecord
  self.table_name = "listings_variant_option_values"

  belongs_to :variant,      class_name: "Listings::Variant"
  belongs_to :option_value, class_name: "Listings::OptionValue"
end
