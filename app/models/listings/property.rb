class Listings::Property < ApplicationRecord
  include MultiTenant
  self.table_name = "listings_properties"

  belongs_to :listing, optional: true
  belongs_to :property_set, class_name: "Listings::PropertySet", optional: true
  acts_as_list scope: [ :listing_id, :property_set_id ]

  before_validation :set_default_position, on: :create

  validates :position, presence: true
  validates :name,     presence: true
  validates :value,    presence: true
  validate  :listing_or_property_set_present

  private

  def listing_or_property_set_present
    errors.add(:base, "must belong to a listing or a property set") if listing.nil? && property_set.nil?
  end

  def set_default_position
    self.position ||= self.class.where(listing_id: listing_id, property_set_id: property_set_id).maximum(:position).to_i + 1
  end
end
