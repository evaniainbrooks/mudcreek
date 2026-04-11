class InquiryForm < ApplicationRecord
  include MultiTenant

  belongs_to :notification_recipient, class_name: "User"
  has_many :inquiries, dependent: :destroy

  validates :name,                    presence: true
  validates :notification_recipient,  presence: true
  validates :slug,                    presence: true,
                                      format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
                                      uniqueness: { scope: :tenant_id }

  before_validation :derive_slug, on: :create, if: -> { slug.blank? && name.present? }

  scope :published, -> { where(published: true) }

  def to_param = slug

  def self.ransackable_attributes(_auth_object = nil)
    %w[name slug published created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[notification_recipient inquiries]
  end

  private

  def derive_slug
    self.slug = name.parameterize
  end
end
