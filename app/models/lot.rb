class Lot < ApplicationRecord
  include MultiTenant
  include NativeEnum
  include HasHashid

  belongs_to :owner, class_name: "User"
  has_one    :address, as: :addressable, dependent: :destroy
  has_many   :listings, dependent: :destroy
  has_one    :settlement, dependent: :destroy

  accepts_nested_attributes_for :address, allow_destroy: true
  has_one_attached :listing_placeholder

  monetize :seller_fee_cents,    with_model_currency: :currency, allow_nil: true
  monetize :payout_amount_cents, with_model_currency: :currency, allow_nil: true

  native_enum :state, %i[submitted received auctioned settled paid]

  validates :name, presence: true

  def currency = tenant&.currency

  scope :commission_present, ->(val = nil) {
    return all if val.nil? || val.to_s.blank?
    ActiveModel::Type::Boolean.new.cast(val) ? where.not(commission_rate: nil) : where(commission_rate: nil)
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name number owner_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end

  def self.ransackable_scopes(_auth_object = nil) = %w[commission_present]
  def self.ransackable_scopes_skip_sanitize_args(_auth_object = nil) = %w[commission_present]
end
