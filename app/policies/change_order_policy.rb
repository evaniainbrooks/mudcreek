class ChangeOrderPolicy < ApplicationPolicy
  def send_for_signature? = update?
end
