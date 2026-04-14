class Improvmx::Domain < ApplicationRecord
  include MultiTenant
  include NativeEnum

  native_enum :status, %i[unchecked verified failed]

  validates :tenant_id, uniqueness: true
end
