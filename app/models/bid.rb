class Bid < ApplicationRecord
  include NativeEnum

  belongs_to :auction_registration
  belongs_to :auction_listing

  native_enum :state, %i[placed cancelled]

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
