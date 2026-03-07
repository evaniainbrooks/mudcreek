class RentalBooking < ApplicationRecord
  include MultiTenant

  belongs_to :listing
  belongs_to :cart_item, optional: true

  validates :cart_item_id, uniqueness: true, allow_nil: true
  validates :start_at, :end_at, :expires_at, presence: true
  validate  :end_after_start
  validate  :minimum_duration
  validate  :no_overlap

  private

  def minimum_duration
    return unless listing && start_at && end_at && end_at > start_at
    min_minutes = listing.rental_rate_plans.minimum(:duration_minutes)
    return unless min_minutes
    duration_minutes = (end_at - start_at) / 60
    if duration_minutes < min_minutes
      errors.add(:base, "Rental must be at least #{min_minutes} minutes")
    end
  end

  def end_after_start
    return unless start_at && end_at
    errors.add(:end_at, "must be after start time") if end_at <= start_at
  end

  def no_overlap
    return unless listing && start_at && end_at
    overlapping = RentalBooking.where(listing: listing)
      .where.not(id: id)
      .where("expires_at > ?", Time.current)
      .where("start_at < ? AND end_at > ?", end_at, start_at)
    if overlapping.count >= listing.quantity
      errors.add(:base, "This equipment is not available for the selected period")
    end
  end
end
