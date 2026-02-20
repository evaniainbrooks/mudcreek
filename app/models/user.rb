class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.ransackable_attributes(_auth_object = nil)
    %w[email_address created_at]
  end
end
