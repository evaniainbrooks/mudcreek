class RolePolicy < ApplicationPolicy
  def destroy?
    permitted?(:destroy) && record.users.none?
  end
end
