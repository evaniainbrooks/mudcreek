class DeliveryMethod < ApplicationRecord
  include MultiTenant

  monetize :price_cents

  validates :name, presence: true, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
