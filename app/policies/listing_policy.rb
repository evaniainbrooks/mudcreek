class ListingPolicy < ApplicationPolicy
  def reorder?
    permitted?(:reorder)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
