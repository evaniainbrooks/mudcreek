class Offer < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :listing
  belongs_to :user

  native_enum :state, %i[pending accepted declined]

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
