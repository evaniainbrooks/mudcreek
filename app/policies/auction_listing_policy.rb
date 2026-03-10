class AuctionListingPolicy < ApplicationPolicy
  actions :create, :destroy, :update

  def reorder? = permitted?(:reorder)
end
