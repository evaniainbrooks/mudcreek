class CreateSenderSignatureJob < ApplicationJob
  queue_as :default

  def perform(tenant_id, from_email, name)
    tenant = Tenant.find(tenant_id)
    Current.tenant = tenant

    result = PostmarkClient.new.create_signature(from_email: from_email, name: name)

    if result[:success]
      attrs = result[:signature]
      record = SenderSignature.create!(
        tenant: tenant,
        external_id: attrs[:id],
        name: attrs[:name],
        email_address: attrs[:email_address],
        confirmed: attrs[:confirmed],
        dkim_verified: attrs[:dkim_verified],
        spf_verified: attrs[:spf_verified],
        return_path_domain_verified: attrs[:return_path_domain_verified]
      )
      broadcast_row(tenant, record)
      broadcast_flash(tenant, :notice, "Sender signature #{record.email_address} was created. Check your inbox to confirm.")
    else
      broadcast_flash(tenant, :alert, "Failed to create sender signature: #{result[:error]}")
    end
  end

  private

  def broadcast_row(tenant, record)
    Turbo::StreamsChannel.broadcast_append_to(
      "sender_signatures_#{tenant.id}",
      target: "sender-signatures-list",
      partial: "admin/sender_signatures/signature_row",
      locals: { sender_signature: record }
    )
  end

  def broadcast_flash(tenant, type, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "sender_signatures_#{tenant.id}",
      target: "flash",
      partial: "shared/flash_message",
      locals: { type: type.to_s, message: message }
    )
  end
end
