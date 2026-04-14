class SyncSenderSignaturesJob < ApplicationJob
  queue_as :default

  def perform(tenant_id)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    remote = PostmarkClient.new.list_signatures
    sync(tenant, remote)
  end

  private

  def sync(tenant, remote)
    remote_by_external_id = remote.index_by { |s| s[:id] }
    existing = SenderSignature.where(tenant: tenant).index_by(&:external_id)

    remote_by_external_id.each do |external_id, attrs|
      record = existing[external_id] || SenderSignature.new(tenant: tenant, external_id: external_id)
      record.assign_attributes(
        name: attrs[:name],
        email_address: attrs[:email_address],
        confirmed: attrs[:confirmed],
        dkim_verified: attrs[:dkim_verified],
        spf_verified: attrs[:spf_verified],
        return_path_domain_verified: attrs[:return_path_domain_verified]
      )
      record.save! if record.changed?
    end

    stale_ids = existing.keys - remote_by_external_id.keys
    SenderSignature.where(tenant: tenant, external_id: stale_ids).delete_all if stale_ids.any?
  end
end
