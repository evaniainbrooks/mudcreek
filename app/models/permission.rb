class Permission < ApplicationRecord
  RESOURCES = %w[Listing User Role Permission].freeze
  ACTIONS   = %w[index show create update destroy].freeze

  belongs_to :role

  validates :resource, presence: true, inclusion: { in: RESOURCES }
  validates :action, presence: true, inclusion: { in: ACTIONS }, uniqueness: { scope: %i[role_id resource], case_sensitive: false }

  validate :immutable, on: :update

  private

  def immutable
    errors.add(:base, "Permissions cannot be modified after creation")
  end
end
