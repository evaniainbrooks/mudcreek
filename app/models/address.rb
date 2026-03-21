class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  geocoded_by :to_geocode_string
  after_validation :geocode, if: :needs_geocoding?

  VALID_COUNTRY_CODES = ISO3166::Country.all.map(&:alpha2).freeze

  validates :address_type, uniqueness: { scope: [:addressable_type, :addressable_id] }
  validates :country, inclusion: { in: VALID_COUNTRY_CODES, message: "is not a recognised country code" }, allow_blank: true

  def any? = [street_address, city, province, postal_code, country].compact_blank.length.positive?

  def geocoded?
    latitude.present? && longitude.present?
  end

  def to_geocode_string
    to_fs(:long)
  end

  def to_fs(format)
    components = [street_address, city, province, postal_code, country].compact_blank
    if format == :long
      components
    else
      components.take(3)
    end.join(", ")
  end

  private

  def needs_geocoding?
    return false if latitude_changed? || longitude_changed?
    to_geocode_string.present? && (changed & %w[street_address city province postal_code country]).any?
  end
end
