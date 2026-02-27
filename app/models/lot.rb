class Lot < ApplicationRecord
  include MultiTenant

  belongs_to :owner, class_name: "User"
  has_many :listings, dependent: :nullify
  has_one_attached :listing_placeholder

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name number]
  end
end
