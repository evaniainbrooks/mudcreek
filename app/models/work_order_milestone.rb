class WorkOrderMilestone < ApplicationRecord
  belongs_to :work_order, inverse_of: :work_order_milestones
  has_many :invoices, foreign_key: :work_order_milestone_id, dependent: :nullify, inverse_of: :work_order_milestone

  acts_as_list scope: :work_order

  monetize :amount_cents, with_model_currency: :currency

  validates :name,         presence: true
  validates :trigger_state, presence: true, inclusion: { in: ->(_) { WorkOrder.states.keys } }
  validates :percentage, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validate  :total_percentage_within_bounds, on: :create

  def prospective_amount(work_order) = Money.new((work_order.total_cents * percentage / 100.0).round, work_order.currency)

  def currency = work_order&.currency

  private

  def total_percentage_within_bounds
    return unless work_order.present?
    sibling_total = work_order.work_order_milestones.reject { |m| m == self }.sum(&:percentage)
    if sibling_total + percentage.to_i > 100
      errors.add(:percentage, "would bring total milestones above 100%")
    end
  end
end
