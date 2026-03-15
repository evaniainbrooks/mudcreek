class SettlementLineItem < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :settlement
  belongs_to :listing, optional: true

  native_enum :line_item_type, %i[hammer_price seller_commission seller_fee]

  validates :description, :amount_cents, presence: true

  monetize :amount_cents, with_model_currency: :currency
  def currency = settlement.lot.currency
end
