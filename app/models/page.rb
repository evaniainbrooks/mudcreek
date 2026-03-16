class Page < ApplicationRecord
  include MultiTenant

  has_rich_text :body

  validates :title, presence: true
  validates :slug, presence: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
    uniqueness: { scope: :tenant_id }

  before_validation :derive_slug, on: :create, if: -> { slug.blank? && title.present? }

  scope :published,      -> { where(published: true) }
  scope :in_nav,         -> { published.where(show_in_nav: true).order(:position, :id) }
  scope :in_footer,      -> { published.where(show_in_footer: true).order(:position, :id) }

  private

  def derive_slug
    self.slug = title.parameterize
  end
end
