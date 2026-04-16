class GalleryWidget < Widget
  belongs_to :gallery

  validates :gallery_id, presence: true
end
