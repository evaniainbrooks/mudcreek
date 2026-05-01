class User < ApplicationRecord
  include MultiTenant

  has_secure_password

  generates_token_for :activation, expires_in: 24.hours do
    activated_at
  end
  has_many :sessions,         dependent: :destroy, inverse_of: :user
  has_many :oauth_identities, dependent: :destroy
  belongs_to :role, optional: true
  has_many :listings, foreign_key: :owner_id, dependent: :destroy
  has_many :lots, foreign_key: :owner_id, dependent: :destroy
  has_many :qr_codes, foreign_key: :owner_id, dependent: :nullify
  has_many :cart_items, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :auction_registrations, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :cart_listings, through: :cart_items, source: :listing
  has_many :watchlist_items, dependent: :destroy
  has_many :watched_listings, through: :watchlist_items, source: :listing
  has_many :check_ins, dependent: :destroy
  has_many :checked_in_locations, through: :check_ins, source: :location
  has_many :schedule_event_passes, dependent: :destroy
  has_many :schedule_event_registrations, dependent: :destroy
  has_many :user_locations, dependent: :destroy
  has_many :locations, through: :user_locations
  has_many :category_interests, class_name: "UserCategoryInterest", dependent: :destroy
  has_many :interested_categories, through: :category_interests, source: :category, class_name: "Listings::Category"
  has_one :address,      -> { where(address_type: "profile") }, class_name: "Address", as: :addressable
  has_one :cart_address,  -> { where(address_type: "cart") },    class_name: "Address", as: :addressable
  has_one :verification, class_name: "Users::Verification", dependent: :destroy
  has_many :inquiry_forms, foreign_key: :notification_recipient_id, dependent: :destroy
  has_many :inquiries, dependent: :nullify
  has_many :owned_inquiries, class_name: "Inquiry", foreign_key: :owner_id, dependent: :nullify
  has_many :subscription_users, dependent: :destroy
  has_many :subscriptions, through: :subscription_users
  has_many :kids, dependent: :destroy
  has_many :rank_awards, as: :rankable, dependent: :destroy
  has_many :awarded_rank_awards, class_name: "RankAward", foreign_key: :awarded_by_id, dependent: :nullify

  before_destroy { Address.where(addressable: self).delete_all }
  accepts_nested_attributes_for :address, update_only: true
  accepts_nested_attributes_for :verification
  accepts_nested_attributes_for :kids, allow_destroy: true, reject_if: :all_blank

  scope :activated, -> { where.not(activated_at: nil) }
  scope :active,    -> { where(disabled_at: nil) }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password_digest, presence: true

  def name
    [first_name, last_name].join(" ")
  end

  def activated?
    activated_at.present?
  end

  def disabled?
    disabled_at.present?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name email_address created_at role_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
