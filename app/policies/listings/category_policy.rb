class Listings::CategoryPolicy < ApplicationPolicy
  def destroy?
    permitted?(:destroy) && record.category_assignments.none?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
