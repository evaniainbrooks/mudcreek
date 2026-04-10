class Ledger::Entry < ApplicationRecord
  include MultiTenant
  include NativeEnum

  self.table_name = "ledger_entries"

  belongs_to :ledger
  belongs_to :user, optional: true

  has_one_attached :receipt

  native_enum :entry_type, %i[credit debit]

  validates :description, presence: true
  validates :entry_type, presence: true
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :taxed, inclusion: { in: [true, false] }

  scope :ordered, -> { order(recorded_at: :desc, id: :desc) }
  scope :credits, -> { where(entry_type: "credit") }
  scope :debits,  -> { where(entry_type: "debit") }

  def subtotal
    return nil unless amount
    return amount unless taxed?
    (amount / (1 + ledger.tax_rate)).round(2)
  end

  def tax_amount
    return BigDecimal("0") unless amount && taxed?
    amount - subtotal
  end
end
