class Tenant < ApplicationRecord
  has_rich_text :description

  has_one_attached :logo

  has_one_attached :default_terms_and_conditions

  has_one :address, as: :addressable, dependent: :destroy

  accepts_nested_attributes_for :address

  has_many :lots, dependent: :restrict_with_error
  has_many :listings, dependent: :restrict_with_error
  has_many :users, dependent: :restrict_with_error
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

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z_0-9]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :currency, presence: true
  validates :default, inclusion: { in: [ true, false ] }
  validates :default, uniqueness: { if: :default? }
  validates :custom_domain, format: { with: /\A[a-z0-9\-\.]+\z/, message: "can only contain lowercase letters, numbers, hyphens, and dots" }, allow_blank: true

  def self.default = find_by!(default: true)

  def grant_super_admin_all_permissions! = roles.super_admin.grant_all_permissions!
end
