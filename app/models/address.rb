class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  VALID_COUNTRY_CODES = ISO3166::Country.all.map(&:alpha2).freeze

  validates :address_type, uniqueness: { scope: [:addressable_type, :addressable_id] }
  validates :country, inclusion: { in: VALID_COUNTRY_CODES, message: "is not a recognised country code" }, allow_blank: true

  def any? = [street_address, city, province, postal_code, country].compact_blank.length.positive?

  def to_fs(format)
    components = [street_address, city, province, postal_code, country].compact_blank
    if format == :long
      components
    else
      components.take(3)
    end.join(", ")
  end
end
