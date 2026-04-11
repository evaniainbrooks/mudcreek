class Inquiry < ApplicationRecord
  include MultiTenant

  belongs_to :inquiry_form
  belongs_to :user, optional: true

  validates :name,    presence: true
  validates :email,   presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
  validates :phone,   format: { with: /\A[\d\s\+\-\(\)]+\z/, allow_blank: true }

  def guest? = user_id.nil?

  def self.ransackable_attributes(_auth_object = nil)
    %w[name email created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inquiry_form user]
  end
end
