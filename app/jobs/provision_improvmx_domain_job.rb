class ProvisionImprovmxDomainJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    client = ImprovmxClient.new
    result = client.get_domain(tenant.custom_domain)

    api_response = if result[:success] && result[:domain].present?
      result[:domain]
    else
      create_result = client.create_domain(tenant.custom_domain)
      create_result[:domain]
    end

    return unless api_response.present?

    record = Improvmx::Domain.find_or_initialize_by(tenant: tenant)
    record.api_response = api_response
    record.save!
  end
end
