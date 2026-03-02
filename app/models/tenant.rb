class Tenant < ApplicationRecord
  has_rich_text :description

  has_one_attached :logo

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

  validates :name, presence: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z_0-9]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :currency, presence: true
  validates :default, inclusion: { in: [ true, false ] }
  validates :default, uniqueness: { if: :default? }

  def self.default = find_by!(default: true)
end
