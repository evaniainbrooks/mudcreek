class Lot < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :owner, class_name: "User"
  has_one    :address, as: :addressable, dependent: :destroy
  has_many   :listings, dependent: :nullify

  accepts_nested_attributes_for :address, allow_destroy: true
  has_one_attached :listing_placeholder

  monetize :seller_fee_cents,    with_model_currency: :currency, allow_nil: true
  monetize :payout_amount_cents, with_model_currency: :currency, allow_nil: true

  native_enum :state, %i[submitted received auctioned settled paid]

  validates :name, presence: true

  def currency = tenant&.currency

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name number]
  end
end
