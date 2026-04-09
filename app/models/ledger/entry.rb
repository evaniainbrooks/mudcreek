class Ledger::Entry < ApplicationRecord
  include MultiTenant
  include NativeEnum

  self.table_name = "ledger_entries"

  belongs_to :ledger
  belongs_to :user, optional: true

  native_enum :entry_type, %i[credit debit]

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(recorded_at: :desc, id: :desc) }
  scope :credits, -> { where(entry_type: "credit") }
  scope :debits,  -> { where(entry_type: "debit") }
end
