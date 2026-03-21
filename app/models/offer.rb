class Offer < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :listing
  belongs_to :user, optional: true
  has_one :invoice

  native_enum :state, %i[pending accepted declined]

  monetize :amount_cents, with_model_currency: :currency

  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :listing_id, uniqueness: { conditions: -> { where(state: :accepted) }, message: "already has an accepted offer" }, if: :accepted?
  validate :user_or_guest_contact_present

  def guest?
    user_id.nil?
  end

  def contact_email
    user&.email_address || guest_email
  end

  after_create_commit :record_category_interest
  after_update :mark_listing_sold, if: -> { saved_change_to_state?(to: "accepted") }
  after_update :generate_offer_invoice, if: -> { saved_change_to_state?(to: "accepted") }

  def currency = tenant&.currency

  private

  def user_or_guest_contact_present
    return if user.present?
    errors.add(:base, "must provide an email or phone number") if guest_email.blank? && guest_phone.blank?
  end

  def record_category_interest
    return unless user
    UserCategoryInterest.record_for(user: user, listing: listing)
  end

  def mark_listing_sold
    listing.sold!
  end

  def generate_offer_invoice
    return unless user

    invoice = Invoice.create!(
      user: user,
      offer: self,
      total_cents: amount_cents
    )
    invoice.invoice_items.create!(
      listing: listing,
      name: listing.name,
      amount_cents: amount_cents
    )
    CreateLotSettlementJob.perform_later(listing.id, hammer_price_cents: amount_cents)
    ListingMailer.offer_accepted(invoice).deliver_later
  end

  public

  def self.ransackable_attributes(_auth_object = nil)
    %w[state amount_cents created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[listing user]
  end
end
