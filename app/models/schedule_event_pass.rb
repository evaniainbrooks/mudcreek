class ScheduleEventPass < ApplicationRecord
  include MultiTenant

  belongs_to :user

  scope :active, -> { where("credits_remaining > 0 AND (expires_at IS NULL OR expires_at >= ?)", Date.current) }

  validates :credits_remaining, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
