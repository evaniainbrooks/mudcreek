class Role < ApplicationRecord
  include MultiTenant

  has_many :users, dependent: :restrict_with_error
  has_many :permissions, dependent: :destroy

  validates :name,
    presence: true,
    uniqueness: { scope: :tenant_id, case_sensitive: false },
    format: { with: /\A[a-z_]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :description, presence: true

  def name
    ActiveSupport::StringInquirer.new(super) if super
  end

  def grant_all_permissions!
    Permission::RESOURCES.each do |resource|
      Permission::ACTIONS.each do |action|
        permissions.find_or_create_by!(resource:, action:, tenant:)
      end
    end
  end
end
