class AuctionRegistrationPolicy < ApplicationPolicy
  actions :index, :create, :update, :destroy

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
