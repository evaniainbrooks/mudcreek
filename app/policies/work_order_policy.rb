class WorkOrderPolicy < ApplicationPolicy
  def send_estimate? = update?
  def advance_state? = update?
  def estimate? = show?
end
