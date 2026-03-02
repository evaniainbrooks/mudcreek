class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  validates :address_type, uniqueness: { scope: [:addressable_type, :addressable_id] }
end
