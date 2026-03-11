class Auction < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_one :address, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  has_one_attached :poster
  has_one_attached :terms_and_conditions

  has_rich_text :description

  has_many :auction_listings, dependent: :destroy
  has_many :listings, through: :auction_listings
  has_many :auction_registrations, dependent: :destroy
  has_many :invoices, dependent: :destroy

  has_one :bid_increment_schedule, dependent: :destroy
  accepts_nested_attributes_for :bid_increment_schedule, allow_destroy: true

  delegate :email_address, to: :tenant, prefix: :tenant, allow_nil: true

  validates :name, presence: true
  validates :admin_email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

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

  def starts_at_in_time_zone
    starts_at&.in_time_zone(timezone)
  end

  def ends_at_in_time_zone
    ends_at&.in_time_zone(timezone)
  end

  def effective_admin_email_address
    admin_email_address.presence || tenant_email_address
  end

  def effective_bid_increment_schedule
    bid_increment_schedule || tenant&.default_bid_increment_schedule
  end

  def recalculate_listing_end_times!
    return unless ends_at.present?
    auction_listings.order(:position).each do |al|
      al.update_column(:ends_at, ends_at + al.end_offset)
    end
  end

  scope :unreconciled, -> { where(reconciled: false) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name published reconciled auto_approve starts_at ends_at timezone]
  end

  private

  def ends_at_after_starts_at
    return unless starts_at.present? && ends_at.present?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
