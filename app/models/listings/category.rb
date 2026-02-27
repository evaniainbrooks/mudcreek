class Listings::Category < ApplicationRecord
  include MultiTenant

  has_rich_text :description

  has_many :category_assignments, foreign_key: :listings_category_id, dependent: :destroy
  has_many :listings, through: :category_assignments

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name]
  end
end
