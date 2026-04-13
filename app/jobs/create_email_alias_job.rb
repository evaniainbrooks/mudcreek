class CreateEmailAliasJob < ApplicationJob
  queue_as :default

  def perform(tenant_id, alias_name, forward)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    result = ImprovmxClient.new.create_alias(tenant.custom_domain, alias_name, forward)

    if result[:success]
      data = result[:alias]
      record = EmailAlias.create!(
        tenant: tenant,
        external_id: data["id"],
        alias: data["alias"],
        forward: data["forward"]
      )
      broadcast_row(tenant, record)
      broadcast_flash(tenant, :notice, "Alias #{record.alias}@#{PublicSuffix.domain(tenant.custom_domain)} was created.")
    else
      broadcast_flash(tenant, :alert, "Failed to create alias: #{result[:error]}")
    end
  end

  private

  def broadcast_row(tenant, record)
    Turbo::StreamsChannel.broadcast_append_to(
      "email_aliases_#{tenant.id}",
      target: "email-aliases-list",
      partial: "admin/email_aliases/alias_row",
      locals: { email_alias: record }
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
