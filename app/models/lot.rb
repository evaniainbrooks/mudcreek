class Lot < ApplicationRecord
  include MultiTenant

  belongs_to :owner, class_name: "User"
  has_one    :address, as: :addressable, dependent: :destroy
  has_many   :listings, dependent: :nullify

  accepts_nested_attributes_for :address, allow_destroy: true
  has_one_attached :listing_placeholder

  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name number]
  end
end
