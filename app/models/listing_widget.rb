class ListingWidget < Widget
  belongs_to :listing

  validates :listing_id, presence: true
end
