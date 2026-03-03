class Transaction < ApplicationRecord
  include NativeEnum

  belongs_to :order

  native_enum :state, %i[pending succeeded failed]

  validates :order_id, uniqueness: { conditions: -> { where(state: "succeeded") } }

  before_validation :ensure_uuid, on: :create

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
