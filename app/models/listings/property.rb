class Listings::Property < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_properties"

  belongs_to :listing
  acts_as_list scope: :listing

  before_validation :set_default_position, on: :create

  validates :position, presence: true
  validates :name,     presence: true
  validates :value,    presence: true

  private

  def set_default_position
    self.position ||= self.class.where(listing_id: listing_id).maximum(:position).to_i + 1
  end
end
