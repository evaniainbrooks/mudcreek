class BidIncrementTier < ApplicationRecord
  belongs_to :bid_increment_schedule

  validates :min_amount_cents, :increment_cents,
    presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :increment_cents, numericality: { greater_than: 0 }
end
