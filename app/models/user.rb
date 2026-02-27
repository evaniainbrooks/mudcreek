class User < ApplicationRecord
  include MultiTenant

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role, optional: true
  has_many :listings, foreign_key: :owner_id, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :cart_listings, through: :cart_items, source: :listing

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password_digest, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name email_address created_at role_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
