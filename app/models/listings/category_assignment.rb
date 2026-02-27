class Listings::CategoryAssignment < ApplicationRecord
  belongs_to :listing
  belongs_to :category, class_name: "Listings::Category", foreign_key: :listings_category_id

  validates :listings_category_id, uniqueness: { scope: :listing_id }
end
