class Transaction < ApplicationRecord
  include NativeEnum

  belongs_to :order

  native_enum :state, %i[pending succeeded failed]

  validates :order_id, uniqueness: { conditions: -> { where(state: "succeeded") } }
  validates :uuid, presence: true
  validates :uuid, uniqueness: true
  validates :amount_cents, presence: true

  before_validation :ensure_uuid, on: :create

  monetize :amount_cents, with_model_currency: :currency

  def currency = order.tenant&.currency

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
