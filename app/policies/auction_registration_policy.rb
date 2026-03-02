class AuctionRegistrationPolicy < ApplicationPolicy
  actions :index, :create, :destroy

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
