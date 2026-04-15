class NavbarItemPolicy < ApplicationPolicy
  def reorder? = permitted?(:reorder)
end
