class Role < ApplicationRecord
  include MultiTenant

  has_many :users, dependent: :restrict_with_error
  has_many :permissions, dependent: :destroy

  validates :name,
    presence: true,
    uniqueness: { scope: :tenant_id, case_sensitive: false },
    format: { with: /\A[a-z_]+\z/, message: "can only contain lowercase letters and underscores" }
  validates :description, presence: true

  scope :super_admin, -> { find_by!(name: "super_admin") }
  scope :admin, -> { find_by!(name: "admin") }

  def name
    ActiveSupport::StringInquirer.new(super) if super
  end

  def grant_all_permissions!
    existing = permissions.pluck(:resource, :action).to_set

    missing = Permission::RESOURCES.flat_map do |resource|
      policy_class = "#{resource}Policy".safe_constantize
      Permission::ACTIONS.filter_map do |action|
        next unless policy_class&.method_defined?(:"#{action}?")
        next if existing.include?([resource, action])
        { resource:, action:, role_id: id, tenant_id: }
      end
    end

    Permission.insert_all(missing) if missing.any?
  end
end
