class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :listings, foreign_key: :owner_id, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :password_digest, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[email_address created_at]
  end
end
