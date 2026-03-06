class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  validates :address_type, uniqueness: { scope: [:addressable_type, :addressable_id] }

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
