class Listings::RentalRatePlan < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_rental_rate_plans"

  belongs_to :listing
  acts_as_list scope: :listing

  monetize :price_cents

  validates :label,            presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents,      presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
