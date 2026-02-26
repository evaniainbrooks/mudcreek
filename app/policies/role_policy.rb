class RolePolicy < ApplicationPolicy
  def destroy?
    permitted?(:destroy) && record.users.none?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
