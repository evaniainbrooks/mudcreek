class BidIncrementSchedule < ApplicationRecord
  include MultiTenant

  belongs_to :auction, optional: true

  validates :auction_id, uniqueness: true, allow_nil: true

  has_many :tiers,
    -> { order(:min_amount_cents) },
    class_name: "BidIncrementTier",
    dependent: :destroy

  accepts_nested_attributes_for :tiers,
    allow_destroy: true,
    reject_if: :all_blank

  def increment_for(amount_cents)
    tiers.select { |t| t.min_amount_cents <= amount_cents }.last&.increment_cents || 0
  end
end
