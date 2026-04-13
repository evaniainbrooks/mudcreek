class CheckImprovmxDomainJob < ApplicationJob
  queue_as :default

  CACHE_TTL = 1.hour

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    result = ImprovmxService.new.check_domain(tenant.custom_domain)
    Rails.cache.write(cache_key(tenant), result, expires_in: CACHE_TTL)

    Turbo::StreamsChannel.broadcast_replace_to(
      "improvmx_check_#{tenant.id}",
      target: "improvmx-status",
      partial: "admin/email_aliases/status",
      locals: { result:, tenant: }
    )
  end

  private

  def cache_key(tenant) = "improvmx_domain_check_#{tenant.id}"
end
