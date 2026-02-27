class Listing < ApplicationRecord
  include MultiTenant
  include HasHashid
  include NativeEnum

  belongs_to :owner, class_name: "User"
  belongs_to :lot, optional: true

  acts_as_list scope: :tenant, add_new_at: :bottom

  native_enum :state, %i[on_sale sold cancelled]

  has_many :category_assignments, class_name: "Listings::CategoryAssignment", dependent: :destroy
  has_many :categories, through: :category_assignments, class_name: "Listings::Category", source: :category

  has_rich_text :description
  has_many_attached :images
  has_many_attached :videos
  has_many_attached :documents

  monetize :price_cents
  monetize :acquisition_price_cents, allow_nil: true

  ALLOWED_DOCUMENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :documents_content_type

  private

  def documents_content_type
    documents.each do |doc|
      next if ALLOWED_DOCUMENT_TYPES.include?(doc.content_type)
      errors.add(:documents, "#{doc.filename} must be a PDF, DOC, DOCX, or XLSX file")
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name price_cents acquisition_price_cents quantity owner_id published state created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[owner categories lot]
  end
end
