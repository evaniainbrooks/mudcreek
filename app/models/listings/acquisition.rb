class Listings::Acquisition < ApplicationRecord
  include MultiTenant

  belongs_to :listing

  monetize :unit_price_cents, allow_nil: true

  validates :quantity,    presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :acquired_on, presence: true

  after_create_commit  { listing.increment!(:quantity, by: quantity) }
  before_destroy       { listing.decrement!(:quantity, by: quantity) }
end
