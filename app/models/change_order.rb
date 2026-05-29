class ChangeOrder < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :work_order, inverse_of: :change_orders

  has_one  :invoice, dependent: :nullify
  has_one_attached :document_pdf

  native_enum :status, %i[draft signature_sent signed]

  monetize :amount_cents, with_model_currency: :currency

  validates :number,      presence: true, uniqueness: true
  validates :description, presence: true
  validates :amount_cents, numericality: { only_integer: true }

  before_validation :assign_number, on: :create

  def currency = work_order&.currency
  def to_param = number

  private

  def assign_number
    self.number ||= "CO-#{SecureRandom.alphanumeric(10).upcase}"
  end
end
