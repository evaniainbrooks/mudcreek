module MultiTenant
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant

    before_validation :set_tenant, on: :create

    default_scope { where(tenant: Current.tenant) if Current.tenant }
  end

  private

  def set_tenant
    self.tenant ||= Current.tenant
  end
end
