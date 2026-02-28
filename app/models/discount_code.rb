class DiscountCode < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :discount_type, %i[fixed percentage]

  monetize :amount_cents

  def active?
    return false if start_at.present? && start_at > Time.current
    return false if end_at.present? && end_at < Time.current
    true
  end

  validates :key, presence: true, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :end_at_after_start_at, if: -> { start_at.present? && end_at.present? }

  private

  def end_at_after_start_at
    errors.add(:end_at, "must be after start time") if end_at <= start_at
  end
end
