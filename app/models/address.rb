class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  validates :address_type, uniqueness: { scope: [:addressable_type, :addressable_id] }

  def to_fs(format)
    if format == :long
      [street_address, city, province, postal_code, country].compact.join(", ")
    else
      [city, country].compact.join(", ")
    end
  end
end
