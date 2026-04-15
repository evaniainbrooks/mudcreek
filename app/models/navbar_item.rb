class NavbarItem < ApplicationRecord
  include MultiTenant

  acts_as_list scope: :tenant

  validates :title, presence: true
  validates :path, presence: true

  scope :ordered, -> { order(:position, :id) }
end
