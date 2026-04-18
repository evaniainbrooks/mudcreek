class SubscriptionUserPolicy < ApplicationPolicy
  actions(:create) { user.admin? }

  def destroy?
    user.admin?
  end
end
