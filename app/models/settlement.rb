class Settlement < ApplicationRecord
  include MultiTenant

  belongs_to :lot
  has_many :settlement_line_items, dependent: :destroy

  validates :lot_id, uniqueness: true

  def net_payout_cents
    income     = settlement_line_items.where(line_item_type: :hammer_price).sum(:amount_cents)
    deductions = settlement_line_items.where(line_item_type: %i[seller_commission seller_fee]).sum(:amount_cents)
    income - deductions
  end

  def currency = lot.currency
  monetize :net_payout_cents, with_model_currency: :currency
end
