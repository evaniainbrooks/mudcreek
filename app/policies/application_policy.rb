# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    permitted?(:index)
  end

  def show?
    permitted?(:show)
  end

  def create?
    permitted?(:create)
  end

  def new?
    create?
  end

  def update?
    permitted?(:update)
  end

  def edit?
    update?
  end

  def destroy?
    permitted?(:destroy)
  end

  private

  def permitted?(action)
    resource_name = record.is_a?(Class) ? record.name : record.class.name
    user.role&.permissions&.exists?(resource: resource_name, action: action.to_s)
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
