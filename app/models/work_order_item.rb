class WorkOrderItem < ApplicationRecord
  belongs_to :work_order, inverse_of: :work_order_items

  acts_as_list scope: :work_order

  monetize :unit_price_cents, with_model_currency: :currency

  validates :name,             presence: true
  validates :tax_exempt,       inclusion: { in: [ true, false ] }
  validates :quantity,         numericality: { greater_than: 0, only_integer: true }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  def line_total_cents = quantity * unit_price_cents

  def line_total = Money.new(line_total_cents, currency)

  def currency = work_order&.currency
end
