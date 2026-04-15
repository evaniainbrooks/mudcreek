class Permission < ApplicationRecord
  include MultiTenant

  RESOURCES = %w[
    Auction
    AuctionListing
    AuctionRegistration
    Bid
    Cloudflare::TurnstileWidget
    DeliveryMethod
    DiscountCode
    EmailAlias
    Improvmx::Domain
    Inquiry
    InquiryForm
    Invoice
    Kid
    Ledger
    Ledger::Entry
    Listing
    ListingInferenceBatch
    Listings::Category
    Listings::Delivery
    Listings::DeliveryMethodSet
    Listings::Property
    Listings::PropertySet
    Listings::RentalRatePlan
    Location
    Lot
    NavbarItem
    Offer
    Order
    Page
    Permission
    Postmark::Domain
    QrCode
    Role
    Settlement
    Subscription
    SubscriptionPlan
    Tenant
    User
  ].freeze

  ACTIONS   = %w[index show create update destroy reorder pay].freeze

  belongs_to :role

  def self.ransackable_attributes(_auth_object = nil)
    %w[resource action]
  end

  validates :resource, presence: true, inclusion: { in: RESOURCES }
  validates :action, presence: true, inclusion: { in: ACTIONS }, uniqueness: { scope: %i[role_id resource] }

  validate :action_defined_on_resource, if: -> { resource.present? && action.present? }
  validate :immutable, on: :update

  private

  def action_defined_on_resource
    policy_class = "#{resource}Policy".safe_constantize
    return errors.add(:resource, "does not have a policy") unless policy_class

    unless policy_class.method_defined?(:"#{action}?")
      errors.add(:action, "#{action.inspect} is not defined for #{resource}")
    end
  end

  def immutable
    errors.add(:base, "Permissions cannot be modified after creation")
  end
end
