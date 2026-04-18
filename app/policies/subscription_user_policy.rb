class SubscriptionUserPolicy < ApplicationPolicy
  actions(:create) { permitted?(:create) }

  def destroy?
    permitted?(:destroy)
  end
end
