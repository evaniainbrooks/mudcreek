class Auction < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_one :address, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  has_one_attached :poster

  has_rich_text :description

  has_many :auction_listings, dependent: :destroy
  has_many :listings, through: :auction_listings
  has_many :auction_registrations, dependent: :destroy

  validates :name, presence: true
  validates :end_time_stagger_interval, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :end_time_stagger_interval, numericality: { greater_than_or_equal_to: 30 },
            if: -> { end_time_stagger_interval.present? && end_time_stagger_interval > 0 }
  validates :bidding_extension, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :ends_at_after_starts_at

  validate :stagger_interval_immutable_after_start

  def stagger_interval_immutable_after_start
    return if new_record?
    return unless end_time_stagger_interval_changed?
    return if Time.current < starts_at

    errors.add(:end_time_stagger_interval, "cannot change after auction has started")
  end

  after_create_commit  :schedule_reconciler, if: -> { ends_at.present? }
  after_update_commit  :schedule_reconciler, if: -> { saved_change_to_ends_at? && ends_at.present? }

  scope :unreconciled, -> { where(reconciled: false) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name published reconciled auto_approve starts_at ends_at]
  end

  private

  def schedule_reconciler
    run_at = auction_listings.minimum(:ends_at) || ends_at
    AuctionReconcilerJob.set(wait_until: run_at).perform_later(self)
  end

  def ends_at_after_starts_at
    return unless starts_at.present? && ends_at.present?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
