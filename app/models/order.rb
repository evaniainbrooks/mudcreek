class Order < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user
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

  before_validation :assign_number, on: :create

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

  def record_category_interests
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
end
