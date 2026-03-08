class Invoice < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user
  belongs_to :auction, optional: true
  belongs_to :offer, optional: true

  has_many :invoice_items, dependent: :destroy

  native_enum :status, %i[unpaid paid]

  monetize :total_cents, with_model_currency: :currency

  validates :number, presence: true, uniqueness: true

  before_validation :assign_number, on: :create

  def currency = tenant&.currency

  def to_param
    number
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user auction]
  end

  private

  def assign_number
    self.number = loop do
      candidate = "INV-#{SecureRandom.alphanumeric(8).upcase}"
      break candidate unless Invoice.unscoped.exists?(number: candidate)
    end
  end
end
