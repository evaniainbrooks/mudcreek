class Order < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user, optional: true
  belongs_to :delivery_method, optional: true
  belongs_to :discount_code,   optional: true
  has_many   :order_items, dependent: :destroy
  has_many   :transactions, dependent: :destroy


  native_enum :status, %i[pending paid cancelled]
  enum :source, { online: "online", manual: "manual" }

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
  after_update_commit :record_stock_movements,    if: -> { saved_change_to_status?(to: "paid") }
  after_update_commit :fulfill_class_products,    if: -> { saved_change_to_status?(to: "paid") }

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

  def fulfill_class_products
    return unless user
    order_items.includes(listing: :subscription_plan).each do |item|
      next unless item.listing_id?
      l = item.listing
      if l.schedule_event_credits.present?
        ScheduleEventPass.create!(user: user, credits_remaining: l.schedule_event_credits, tenant: tenant)
      elsif l.subscription_plan_id.present?
        plan = l.subscription_plan
        renews_at = case plan.subscription_type
        when "monthly", "month_to_month" then 1.month.from_now.to_date
        when "annual"                    then 1.year.from_now.to_date
        when "semi_annual"               then 6.months.from_now.to_date
        else                             100.years.from_now.to_date
        end
        sub = plan.subscriptions.create!(renews_at: renews_at, tenant: tenant)
        sub.subscription_users.create!(user: user, primary_contact: true, tenant: tenant)
      end
    end
  end

  def record_stock_movements
    order_items.includes(:listing).each(&:record_stock_movement!)
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.message.include?("listings_quantity_non_negative")
    Rails.logger.warn("Oversell detected on order #{number}: #{e.message}")
    update_columns(status: "cancelled")
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
