class Listings::Category < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_rich_text :description
  has_one_attached :hero_image

  has_many :category_assignments, foreign_key: :listings_category_id, dependent: :destroy
  has_many :listings, through: :category_assignments
  has_many :user_interests, class_name: "UserCategoryInterest", foreign_key: :listings_category_id, dependent: :destroy
  has_many :interested_users, through: :user_interests, source: :user

  validates :name, presence: true, uniqueness: { scope: :tenant_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
