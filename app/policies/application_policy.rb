# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class << self
    def actions(*action_names, &block)
      @_defining_via_macro = true
      if block
        define_method(:"#{action_names.first}?", &block)
        auto_alias(action_names.first)
      else
        action_names.each do |name|
          define_method(:"#{name}?") { permitted?(name) }
          auto_alias(name)
        end
      end
    ensure
      @_defining_via_macro = false
    end

    def method_added(method_name)
      if [:create?, :update?].include?(method_name) && self != ApplicationPolicy && !@_defining_via_macro
        alias_name = method_name == :create? ? :new? : :edit?
        raise "Use `actions :#{method_name.to_s.chomp('?')}` instead of defining `#{method_name}` directly so `#{alias_name}` is aliased automatically"
      end
      super
    end

    private

    def auto_alias(name)
      case name
      when :create then define_method(:new?) { create? }
      when :update then define_method(:edit?) { update? }
      end
    end
  end

  actions :index, :show, :create, :update, :destroy

  private

  def permitted?(action)
    resource_name = record.is_a?(Class) ? record.name : record.class.name
    user.role&.permissions&.exists?(resource: resource_name, action: action.to_s) || false
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
