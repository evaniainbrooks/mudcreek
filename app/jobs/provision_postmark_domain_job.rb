class ProvisionPostmarkDomainJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    root = PublicSuffix.domain(tenant.custom_domain)
    client = PostmarkClient.new

    domain_data = client.find_domain_by_name(root)

    if domain_data.nil?
      result = client.create_domain(root)
      return unless result[:success]

      domain_data = result[:domain]
    end

    record = ::Postmark::Domain.find_or_initialize_by(tenant: tenant)
    record.update!(
      external_id: domain_data["id"],
      api_response: domain_data
    )
  end
end
