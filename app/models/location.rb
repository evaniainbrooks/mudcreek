class Location < ApplicationRecord
  include MultiTenant

  has_many :check_ins, dependent: :destroy
  has_one :address, as: :addressable, dependent: :destroy
  accepts_nested_attributes_for :address, reject_if: :all_blank

  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end
end
