class Listings::Variant < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_variants"

  belongs_to :listing
  has_many :variant_option_values, class_name: "Listings::VariantOptionValue",
           foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values,
           class_name: "Listings::OptionValue", source: :option_value
  has_many :cart_items, dependent: :nullify
  has_one :gallery, foreign_key: :variant_id, dependent: :destroy, inverse_of: :variant
  accepts_nested_attributes_for :gallery

  monetize :price_cents, allow_nil: true, with_model_currency: :currency

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def display_name
    option_values.sort_by { |ov| ov.option.position }.map(&:value).join(" / ")
  end

  def effective_price_cents
    price_cents || listing.price_cents
  end

  def currency = listing.currency
end
