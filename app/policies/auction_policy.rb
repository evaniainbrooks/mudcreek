class AuctionPolicy < ApplicationPolicy
  actions :index, :show, :create, :update, :destroy

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
