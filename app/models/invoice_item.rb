class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :listing, optional: true

  has_one :cart_item, dependent: :nullify

  validates :name, presence: true

  monetize :amount_cents
end
