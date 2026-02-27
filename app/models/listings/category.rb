class Listings::Category < ApplicationRecord
  include MultiTenant
  include HasHashid

  has_rich_text :description

  has_many :category_assignments, foreign_key: :listings_category_id, dependent: :destroy
  has_many :listings, through: :category_assignments

  validates :name, presence: true, uniqueness: { scope: :tenant_id }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
