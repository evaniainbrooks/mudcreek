class Subscription < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :status, %i[active lapsed cancelled]

  belongs_to :subscription_plan
  belongs_to :user

  has_many :invoices, dependent: :nullify

  validates :renews_at, presence: true
  validates :subscription_plan_id, uniqueness: { scope: %i[tenant_id user_id], message: "already assigned to this user" }

  scope :due, -> { active.where(renews_at: ..Date.current) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[status renews_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user subscription_plan]
  end
end
