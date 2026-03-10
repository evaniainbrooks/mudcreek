class Listings::CategoryPolicy < ApplicationPolicy
  def destroy?
    permitted?(:destroy) && record.category_assignments.none?
  end
end
