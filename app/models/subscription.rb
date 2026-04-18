class Subscription < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :status, %i[active lapsed cancelled]

  belongs_to :subscription_plan
  has_many :subscription_users, dependent: :destroy
  has_many :users, through: :subscription_users

  has_many :invoices, dependent: :nullify

  monetize :amount_cents, with_model_currency: :currency

  validates :renews_at, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }, on: :update

  before_create :copy_plan_amount

  scope :due, -> { active.where(renews_at: ..Date.current) }

  def primary_user
    subscription_users.find_by(primary_contact: true)&.user
  end

  def currency
    tenant&.currency
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status renews_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[subscription_plan]
  end

  private

  def copy_plan_amount
    self.amount_cents ||= subscription_plan&.amount_cents
  end
end
