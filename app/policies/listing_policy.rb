class ListingPolicy < ApplicationPolicy
  def reorder?
    permitted?(:reorder)
  end
end
