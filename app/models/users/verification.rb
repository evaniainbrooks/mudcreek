class Users::Verification < ApplicationRecord
  include MultiTenant
  include NativeEnum

  self.table_name = "users_verifications"

  belongs_to :user
  belongs_to :validated_by, class_name: "User", optional: true

  has_one_attached :verification_document

  native_enum :status, %i[not_validated validated]

  validates :verification_document, presence: true
end
