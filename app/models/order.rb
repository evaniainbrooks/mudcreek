class Order < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user, optional: true
  belongs_to :delivery_method, optional: true
  belongs_to :discount_code,   optional: true
  has_many   :order_items, dependent: :destroy
  has_many   :transactions, dependent: :destroy


  native_enum :status, %i[pending paid cancelled]

  monetize :subtotal_cents,       with_model_currency: :currency
  monetize :tax_cents,            with_model_currency: :currency
  monetize :discount_cents,       with_model_currency: :currency
  monetize :delivery_price_cents, with_model_currency: :currency
  monetize :total_cents,          with_model_currency: :currency

  validates :number, presence: true, uniqueness: true
  validates :square_payment_id, uniqueness: true, allow_nil: true
  validates :guest_token, uniqueness: true, allow_nil: true
  validate :user_or_guest_info_present

  before_validation :assign_number, on: :create
  before_validation :assign_guest_token, on: :create

  after_update_commit :record_category_interests, if: -> { saved_change_to_status?(to: "paid") }

  def currency = tenant&.currency

  def self.ransackable_attributes(_auth_object = nil)
    %w[status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  def to_param
    number
  end

  def successful_transaction
    transactions.succeeded.order(created_at: :desc).first
  end

  private

  def user_or_guest_info_present
    errors.add(:base, "must belong to a user or have guest email") if user_id.nil? && guest_email.blank?
  end

  def record_category_interests
    return unless user
    order_items.includes(listing: :categories).each do |item|
      next unless item.listing_id?
      UserCategoryInterest.record_for(user: user, listing: item.listing)
    end
  end

  def assign_number
    self.number = loop do
      candidate = "MC-#{SecureRandom.alphanumeric(8).upcase}"
      break candidate unless Order.exists?(number: candidate)
    end
  end

  def assign_guest_token
    self.guest_token ||= SecureRandom.uuid if user_id.nil?
  end
end
