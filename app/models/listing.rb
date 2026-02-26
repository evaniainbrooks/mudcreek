class Listing < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_rich_text :description
  has_many_attached :images
  has_many_attached :videos
  has_many_attached :documents

  monetize :price_cents

  ALLOWED_DOCUMENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true
  validate :documents_content_type

  private

  def documents_content_type
    documents.each do |doc|
      next if ALLOWED_DOCUMENT_TYPES.include?(doc.content_type)
      errors.add(:documents, "#{doc.filename} must be a PDF, DOC, DOCX, or XLSX file")
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name price_cents owner_id published created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[owner]
  end
end
