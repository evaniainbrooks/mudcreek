class DeleteEmailAliasJob < ApplicationJob
  queue_as :default

  def perform(email_alias_id)
    record = EmailAlias.unscoped.find(email_alias_id)
    tenant = record.tenant
    Current.tenant = tenant

    result = ImprovmxClient.new.delete_alias(tenant.custom_domain, record.alias)

    if result[:success]
      record.destroy!
      broadcast_remove(tenant, email_alias_id)
      broadcast_flash(tenant, :notice, "Alias #{record.alias}@#{PublicSuffix.domain(tenant.custom_domain)} was deleted.")
    else
      broadcast_flash(tenant, :alert, "Failed to delete alias: #{result[:error]}")
    end
  end

  private

  def broadcast_remove(tenant, email_alias_id)
    Turbo::StreamsChannel.broadcast_remove_to(
      "email_aliases_#{tenant.id}",
      target: "email_alias_#{email_alias_id}"
    )
  end

  def broadcast_flash(tenant, type, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "email_aliases_#{tenant.id}",
      target: "flash",
      partial: "shared/flash_message",
      locals: { type: type.to_s, message: message }
    )
  end
end
