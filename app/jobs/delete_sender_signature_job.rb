class DeleteSenderSignatureJob < ApplicationJob
  queue_as :default

  def perform(signature_id)
    record = SenderSignature.unscoped.find(signature_id)
    tenant = record.tenant
    Current.tenant = tenant

    result = PostmarkClient.new.delete_signature(record.external_id)

    if result[:success]
      email = record.email_address
      record.destroy!
      broadcast_remove(tenant, signature_id)
      broadcast_flash(tenant, :notice, "Sender signature #{email} was deleted.")
    else
      broadcast_flash(tenant, :alert, "Failed to delete sender signature: #{result[:error]}")
    end
  end

  private

  def broadcast_remove(tenant, signature_id)
    Turbo::StreamsChannel.broadcast_remove_to(
      "sender_signatures_#{tenant.id}",
      target: "sender_signature_#{signature_id}"
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
