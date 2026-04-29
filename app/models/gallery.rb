class Gallery < ApplicationRecord
  include MultiTenant

  belongs_to :listing, optional: true

  has_rich_text :description

  has_many_attached :photos
  has_many_attached :videos
  has_many_attached :documents

  before_validation :inherit_listing_name

  validates :name, presence: true
  validates :listing_id, uniqueness: true, allow_nil: true

  private

  def inherit_listing_name
    self.name = listing.name if name.blank? && listing.present?
  end

  public

  def self.ransackable_attributes(_auth_object = nil)
    %w[name listing_id]
  end
end
