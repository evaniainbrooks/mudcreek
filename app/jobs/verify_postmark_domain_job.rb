class VerifyPostmarkDomainJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    domain = ::Postmark::Domain.find_by!(tenant: tenant)
    result = PostmarkClient.new.verify_domain(domain.external_id)

    domain.update!(
      status: result[:success] ? :verified : :failed,
      api_response: result[:domain] || domain.api_response
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "postmark_domain_#{tenant.id}",
      target: "postmark-domain-status",
      partial: "admin/sender_signatures/domain_status",
      locals: { domain:, checking: false }
    )
  end
end
