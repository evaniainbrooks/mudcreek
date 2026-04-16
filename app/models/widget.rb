class Widget < ApplicationRecord
  include MultiTenant

  belongs_to :page

  validates :position, presence: true

  default_scope { order(:position) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[type page_id position]
  end
end
