class Auction < ApplicationRecord
  include MultiTenant

  has_one :address, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :address, allow_destroy: true

  has_one_attached :poster
  has_one_attached :cover_photo

  has_rich_text :description

  has_many :auction_listings, dependent: :destroy
  has_many :listings, through: :auction_listings

  validates :name, presence: true
  validate :ends_at_after_starts_at

  scope :unreconciled, -> { where(reconciled: false) }

  private

  def ends_at_after_starts_at
    return unless starts_at.present? && ends_at.present?
    errors.add(:ends_at, "must be after start time") if ends_at <= starts_at
  end
end
