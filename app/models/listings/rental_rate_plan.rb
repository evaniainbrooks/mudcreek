class Listings::RentalRatePlan < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_rental_rate_plans"

  belongs_to :listing
  acts_as_list scope: :listing

  before_validation :set_default_position, on: :create

  monetize :price_cents

  validates :position,         presence: true
  validates :label,            presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents,      presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  private

  def set_default_position
    self.position ||= self.class.where(listing_id: listing_id).maximum(:position).to_i + 1
  end
end
