class RolePolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def destroy?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
