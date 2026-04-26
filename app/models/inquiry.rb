class Inquiry < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :inquiry_form
  belongs_to :user, optional: true
  belongs_to :owner, class_name: "User", optional: true

  native_enum :status, %i[new in_progress resolved spam]

  validates :name,    presence: true
  validates :email,   presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
  validates :phone,   format: { with: /\A[\d\s\+\-\(\)]+\z/, allow_blank: true }

  before_update :assign_owner
  before_update :set_followed_up_at

  def guest? = user_id.nil?

  def self.ransackable_attributes(_auth_object = nil)
    %w[name email created_at status]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[inquiry_form user owner]
  end

  private

  def assign_owner
    self.owner = Current.user if Current.user
  end

  def set_followed_up_at
    self.followed_up_at ||= Time.current unless new?
  end
end
