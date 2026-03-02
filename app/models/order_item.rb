class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :listing, optional: true

  monetize :price_cents

  validates :name, presence: true
end
