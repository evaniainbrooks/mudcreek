class SubscriptionPlan < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :kind, %i[month_to_month]

  has_many :subscriptions, dependent: :restrict_with_error

  monetize :amount_cents, with_model_currency: :currency

  validates :name,         presence: true, uniqueness: { scope: :tenant_id }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :kind,         presence: true

  def currency = tenant&.currency

  def self.ransackable_attributes(_auth_object = nil)
    %w[name kind created_at]
  end
end
