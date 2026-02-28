class Offer < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :listing
  belongs_to :user

  native_enum :state, %i[pending accepted declined]

  monetize :amount_cents

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :one_accepted_offer_per_listing, if: :accepted?

  after_update :mark_listing_sold, if: -> { saved_change_to_state?(to: "accepted") }

  private

  def mark_listing_sold
    listing.sold!
  end

  def one_accepted_offer_per_listing
    scope = listing.offers.accepted
    scope = scope.where.not(id: id) if persisted?
    errors.add(:base, "Listing already has an accepted offer") if scope.exists?
  end

  public

  def self.ransackable_attributes(_auth_object = nil)
    %w[state amount_cents created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[listing user]
  end
end
