class Permission < ApplicationRecord
  include MultiTenant

  RESOURCES = %w[Listing Lot User Role Permission Listings::Category Offer Order DiscountCode DeliveryMethod Listings::RentalRatePlan Auction AuctionListing AuctionRegistration Bid].freeze
  ACTIONS   = %w[index show create update destroy reorder].freeze

  belongs_to :role

  def self.ransackable_attributes(_auth_object = nil)
    %w[resource action]
  end

  validates :resource, presence: true, inclusion: { in: RESOURCES }
  validates :action, presence: true, inclusion: { in: ACTIONS }, uniqueness: { scope: %i[role_id resource] }

  validate :immutable, on: :update

  private

  def immutable
    errors.add(:base, "Permissions cannot be modified after creation")
  end
end
