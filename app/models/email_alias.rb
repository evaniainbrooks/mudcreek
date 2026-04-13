class EmailAlias < ApplicationRecord
  include MultiTenant

  validates :external_id, presence: true, uniqueness: { scope: :tenant_id }
  validates :alias, presence: true
  validates :forward, presence: true
end
