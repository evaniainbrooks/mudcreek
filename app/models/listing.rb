class Listing < ApplicationRecord
  include MultiTenant
  include HasHashid
  include NativeEnum

  belongs_to :owner, class_name: "User"
  belongs_to :lot, optional: true

  acts_as_list scope: :tenant, add_new_at: :bottom

  native_enum :state, %i[on_sale sold cancelled]
  native_enum :pricing_type, %i[firm negotiable]
  native_enum :listing_type, %i[sale rental]

  has_one  :address, as: :addressable, dependent: :destroy
  has_many :order_items, dependent: :nullify
  has_many :invoice_items, dependent: :nullify
  has_many :cart_items, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :rental_rate_plans, class_name: "Listings::RentalRatePlan",
    dependent: :destroy, foreign_key: :listing_id
  has_many :rental_bookings, dependent: :destroy
  has_many :category_assignments, class_name: "Listings::CategoryAssignment", dependent: :destroy
  has_many :categories, through: :category_assignments, class_name: "Listings::Category", source: :category

  has_many :auction_listings, dependent: :destroy
  has_one :auction_listing

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

  before_validation :set_default_position, on: :create
  before_validation :set_rental_price_default

  validates :position, presence: true, uniqueness: { scope: :tenant_id }, on: :update, if: :will_save_change_to_position?
  validates :position, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :price_cents, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :documents_content_type

  accepts_nested_attributes_for :address, allow_destroy: true
  accepts_nested_attributes_for :rental_rate_plans, allow_destroy: true, reject_if: :all_blank

  def rental_rate_plans_to_json
    rental_rate_plans.map { { label: it.label, duration_minutes: it.duration_minutes, price_cents: it.price_cents } }.to_json
  end

  private

  def set_default_position
    self.position ||= acts_as_list_list.maximum(:position).to_i + 1
  end

  def set_rental_price_default
    self.price_cents = 0 if rental? && price_cents.nil?
  end

  def documents_content_type
    documents.each do |doc|
      next if ALLOWED_DOCUMENT_TYPES.include?(doc.content_type)
      errors.add(:documents, "#{doc.filename} must be a PDF, DOC, DOCX, or XLSX file")
    end
  end

  scope :not_in_auction, -> { where.not(id: AuctionListing.select(:listing_id)) }
  scope :auction_assigned, ->(value = nil) {
    return all if value.nil? || value.to_s.blank?
    if ActiveModel::Type::Boolean.new.cast(value)
      where(id: AuctionListing.select(:listing_id))
    else
      where.not(id: AuctionListing.select(:listing_id))
    end
  }

  def self.ransackable_scopes(_auth_object = nil) = %w[auction_assigned]
  def self.ransackable_scopes_skip_sanitize_args(_auth_object = nil) = %w[auction_assigned]

  def self.ransackable_attributes(_auth_object = nil)
    %w[name price_cents acquisition_price_cents quantity owner_id published state pricing_type listing_type created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[owner categories lot]
  end
end
