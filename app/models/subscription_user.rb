class SubscriptionUser < ApplicationRecord
  include MultiTenant

  belongs_to :subscription
  belongs_to :user

  validates :user_id, uniqueness: { scope: :subscription_id, message: "is already on this subscription" }
end
