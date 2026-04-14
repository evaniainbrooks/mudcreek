class SenderSignature < ApplicationRecord
  include MultiTenant

  validates :external_id, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :email_address, presence: true
end
