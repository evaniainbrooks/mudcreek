class Page < ApplicationRecord
  include MultiTenant

  has_rich_text :body

  has_one_attached :hero_image
  has_one_attached :left_column_image
  has_one_attached :right_column_image

  belongs_to :parent, class_name: "Page", optional: true
  has_many :children, class_name: "Page", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent

  belongs_to :inquiry_form, optional: true

  validates :title, presence: true
  validates :slug, presence: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
    uniqueness: { scope: :tenant_id }
  validate :parent_is_not_self
  validate :parent_is_not_a_child

  before_validation :derive_slug, on: :create, if: -> { slug.blank? && title.present? }

  def to_param = slug

  scope :published,      -> { where(published: true) }
  scope :top_level,      -> { where(parent_id: nil) }
  scope :in_nav,         -> { published.where(show_in_nav: true).order(:position, :id) }
  scope :in_footer,      -> { published.where(show_in_footer: true).order(:position, :id) }

  private

  def derive_slug
    self.slug = title.parameterize
  end

  def parent_is_not_self
    errors.add(:parent, "cannot be the page itself") if parent_id.present? && parent_id == id
  end

  def parent_is_not_a_child
    errors.add(:parent, "cannot be a child of this page") if parent_id.present? && children.exists?(id: parent_id)
  end
end
