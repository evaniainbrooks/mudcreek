class WorkOrder < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user, optional: true
  has_many :work_order_items,      -> { order(:position) }, dependent: :destroy, inverse_of: :work_order
  has_many :work_order_milestones, -> { order(:position) }, dependent: :destroy, inverse_of: :work_order
  has_many :invoices, through: :work_order_milestones
  has_one  :address, as: :addressable, dependent: :destroy
  has_one_attached :estimate_pdf

  accepts_nested_attributes_for :work_order_items,      allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :work_order_milestones, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :address

  native_enum :state, %i[draft estimate_sent contracted in_progress completed cancelled]

  monetize :total_cents, with_model_currency: :currency

  validates :number, presence: true, uniqueness: true
  validates :title,  presence: true
  validate  :client_contact_present

  before_validation :assign_number, on: :create
  before_save       :recompute_total

  def guest? = user_id.nil?

  def client_display_name  = user&.name || client_name
  def client_contact_email = user&.email_address || client_email

  def currency = tenant&.currency

  def to_param = number

  def self.ransackable_attributes(_auth_object = nil)
    %w[state title client_name client_email created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  private

  def assign_number
    self.number ||= "WO-#{SecureRandom.alphanumeric(10).upcase}"
  end

  def client_contact_present
    return if user.present? || client_name.present? || client_email.present? || client_phone.present?
    errors.add(:base, "must provide client contact details or select an existing user")
  end

  def recompute_total
    self.total_cents = work_order_items.reject(&:marked_for_destruction?).sum do |item|
      item.quantity.to_i * item.unit_price_cents.to_i
    end
  end
end
