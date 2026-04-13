class SyncEmailAliasesJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    tenant.with_advisory_lock("email_aliases") do
      remote = ImprovmxClient.new.list_aliases(tenant.custom_domain)
      sync(tenant, remote)
    end
  end

  private

  def sync(tenant, remote)
    remote_by_external_id = remote.index_by { |a| a["id"] }
    existing = EmailAlias.where(tenant: tenant).index_by(&:external_id)

    remote_by_external_id.each do |external_id, attrs|
      record = existing[external_id] || EmailAlias.new(tenant: tenant, external_id: external_id)
      record.assign_attributes(alias: attrs["alias"], forward: attrs["forward"])
      record.save! if record.changed?
    end

    stale_ids = existing.keys - remote_by_external_id.keys
    EmailAlias.where(tenant: tenant, external_id: stale_ids).delete_all if stale_ids.any?
  end
end
