class Tenant < ApplicationRecord
  include StoreModel::NestedAttributes

  has_rich_text :description
  has_rich_text :notice

  attribute :features, Tenant::Features.to_type

  has_one_attached :logo
  has_one_attached :favicon
  has_one_attached :listing_placeholder
  has_one_attached :auction_placeholder

  has_one_attached :default_terms_and_conditions

  has_one :address, as: :addressable, dependent: :destroy

  accepts_nested_attributes_for :address
  accepts_nested_attributes_for :features

  has_many :navbar_items, dependent: :destroy
  has_many :lots, dependent: :restrict_with_error
  has_many :listings, dependent: :restrict_with_error
  has_many :users,            dependent: :restrict_with_error
  has_many :oauth_identities, dependent: :restrict_with_error
  has_many :roles, dependent: :restrict_with_error
  has_many :permissions, dependent: :restrict_with_error
  has_many :listing_categories, class_name: "Listings::Category", dependent: :restrict_with_error
  has_many :cart_items, dependent: :restrict_with_error
  has_many :offers, dependent: :restrict_with_error
  has_many :discount_codes, dependent: :restrict_with_error
  has_many :delivery_methods, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :rental_bookings, dependent: :restrict_with_error
  has_many :rental_rate_plans, class_name: "Listings::RentalRatePlan", dependent: :restrict_with_error
  has_many :auctions, dependent: :restrict_with_error
  has_many :invoices, dependent: :destroy
  has_many :qr_codes, dependent: :destroy
  has_many :auction_registrations, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :check_ins, dependent: :destroy
  has_many :verifications, class_name: "Users::Verification", dependent: :destroy

  has_many :email_aliases, dependent: :destroy
  has_many :inquiry_forms, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  has_many :subscription_plans, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :kids, dependent: :destroy

  has_many :social_media_accounts, dependent: :destroy
  has_many :property_sets, class_name: "Listings::PropertySet", dependent: :destroy
  has_many :delivery_method_sets, class_name: "Listings::DeliveryMethodSet", dependent: :destroy
  belongs_to :default_delivery_method_set, class_name: "Listings::DeliveryMethodSet", optional: true
  belongs_to :homepage_page, class_name: "Page", optional: true

  accepts_nested_attributes_for :social_media_accounts, allow_destroy: true, reject_if: :all_blank

  has_one :default_bid_increment_schedule,
    -> { where(auction_id: nil) },
    class_name: "BidIncrementSchedule",
    dependent: :destroy

  accepts_nested_attributes_for :default_bid_increment_schedule

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :homepage_page_id, uniqueness: true, allow_nil: true
  validates :name, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z_0-9]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :currency, presence: true
  validates :default, inclusion: { in: [ true, false ] }
  validates :default, uniqueness: { if: :default? }
  validates :custom_domain, format: { with: /\A[a-z0-9\-\.]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and dots" }, allow_blank: true
  validates :ga4_measurement_id, format: { with: /\AG-[A-Z0-9]+\z/, message: "must be a valid GA4 Measurement ID (e.g. G-XXXXXXXXXX)" }, allow_blank: true
  validates :facebook_pixel_id, format: { with: /\A\d+\z/, message: "must be a numeric Pixel ID" }, allow_blank: true

  HEX_COLOR_RE = /\A#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\z/
  %i[primary_color secondary_color tertiary_color background_color text_color link_color footer_color card_color container_color].each do |attr|
    validates attr, format: { with: HEX_COLOR_RE, message: "must be a valid hex color (e.g. #3a7d44)" }, allow_blank: true
  end

  def timezone = read_attribute(:timezone).presence || Time.zone.name

  def self.default = find_by!(default: true)
end
