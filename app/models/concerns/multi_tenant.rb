module MultiTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant, optional: true

    validates :tenant_id, presence: true

    before_validation :set_tenant, on: :create

    default_scope { where(tenant: Current.tenant) if Current.tenant }
  end

  private

  def set_tenant
    association(:tenant).target ||= Current.tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
