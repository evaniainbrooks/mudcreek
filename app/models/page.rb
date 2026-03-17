class Page < ApplicationRecord
  include MultiTenant

  has_rich_text :body

  has_one_attached :hero_image
  has_one_attached :left_column_image
  has_one_attached :right_column_image

  validates :title, presence: true
  validates :slug, presence: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
    uniqueness: { scope: :tenant_id }

  before_validation :derive_slug, on: :create, if: -> { slug.blank? && title.present? }

  def to_param = slug

  scope :published,      -> { where(published: true) }
  scope :in_nav,         -> { published.where(show_in_nav: true).order(:position, :id) }
  scope :in_footer,      -> { published.where(show_in_footer: true).order(:position, :id) }

  private

  def derive_slug
    self.slug = title.parameterize
  end
end
