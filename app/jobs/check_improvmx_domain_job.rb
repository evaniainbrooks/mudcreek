class CheckImprovmxDomainJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    result = ImprovmxClient.new.check_domain(tenant.custom_domain)

    domain = Improvmx::Domain.find_by!(tenant: tenant)
    domain.update!(
      status: result[:success] ? :verified : :failed,
      check_data: result
    )

    SyncEmailAliasesJob.perform_later(tenant.id) if result[:success]

    Turbo::StreamsChannel.broadcast_replace_to(
      "improvmx_check_#{tenant.id}",
      target: "improvmx-status",
      partial: "admin/email_aliases/status",
      locals: { domain:, checking: false }
    )
  end
end
