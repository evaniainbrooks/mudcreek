class Listing < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_rich_text :description

  monetize :price_cents

  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[name price_cents owner_id created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[owner]
  end
end
