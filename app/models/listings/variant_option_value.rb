class Listings::VariantOptionValue < ApplicationRecord
  self.table_name = "listings_variant_option_values"

  belongs_to :variant,      class_name: "Listings::Variant"
  belongs_to :option_value, class_name: "Listings::OptionValue"

  validates :option_value_id, uniqueness: { scope: :variant_id }
end
