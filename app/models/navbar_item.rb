class NavbarItem < ApplicationRecord
  include MultiTenant

  validates :title, presence: true
  validates :path, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
