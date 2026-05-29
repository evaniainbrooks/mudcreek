class Invoice < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user,                   optional: true
  belongs_to :auction,                optional: true
  belongs_to :offer,                  optional: true
  belongs_to :subscription,           optional: true
  belongs_to :work_order_milestone,   optional: true
  belongs_to :change_order,           optional: true
  has_one    :work_order, through: :work_order_milestone

  has_many :invoice_items, dependent: :destroy
  has_one_attached :receipt

  native_enum :status, %i[unpaid paid]

  monetize :total_cents, with_model_currency: :currency

  validates :number, presence: true, uniqueness: true
  validates :offer_id,        uniqueness: true, allow_nil: true
  validates :change_order_id, uniqueness: true, allow_nil: true
  validate  :user_or_work_order_present

  before_validation :assign_number, on: :create

  after_update_commit :advance_subscription,
    if: -> { saved_change_to_status?(to: "paid") && subscription_id.present? }

  def currency = tenant&.currency

  def to_param
    number
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user auction]
  end

  private

  def user_or_work_order_present
    return if user_id.present? || work_order_milestone_id.present? || change_order_id.present?
    errors.add(:base, "must belong to a user, a work order milestone, or a change order")
  end

  def assign_number
    self.number ||= "INV-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def advance_subscription
    Subscriptions::AdvanceService.new(subscription).call
  end
end
