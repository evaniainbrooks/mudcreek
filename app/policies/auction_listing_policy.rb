class AuctionListingPolicy < ApplicationPolicy
  actions :create, :destroy

  def reorder? = permitted?(:reorder)

  class Scope < ApplicationPolicy::Scope
    def resolve = scope.all
  end
end
