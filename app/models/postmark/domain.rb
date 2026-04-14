class Postmark::Domain < ApplicationRecord
  self.table_name = "postmark_domains"

  include MultiTenant
  include NativeEnum

  native_enum :status, %i[unchecked verified failed]

  validates :tenant_id, uniqueness: true
  validates :external_id, presence: true, uniqueness: true
end
