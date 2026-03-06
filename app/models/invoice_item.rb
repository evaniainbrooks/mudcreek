class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :listing, optional: true

  monetize :amount_cents
end
