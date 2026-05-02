class SubscriptionPlan < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :subscription_type, %i[month_to_month monthly annual semi_annual one_time]

  has_many :subscriptions, dependent: :restrict_with_error
  has_many :listings, dependent: :nullify

  monetize :amount_cents, with_model_currency: :currency

  validates :name,         presence: true, uniqueness: { scope: :tenant_id }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :subscription_type, presence: true

  def currency = tenant&.currency

  def self.ransackable_attributes(_auth_object = nil)
    %w[name subscription_type created_at]
  end
end
