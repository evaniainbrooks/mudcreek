module WorkOrders
  class SendChangeOrderService
    Result = Data.define(:change_order, :error) do
      def success? = error.nil?
    end

    def self.call(change_order:)
      work_order = change_order.work_order

      html = ApplicationController.renderer.render(
        template: "change_orders/document",
        assigns:  { change_order:, work_order: },
        layout:   false
      )

      pdf_bytes = Grover.new(html, format: "A4", print_background: true).to_pdf

      change_order.document_pdf.attach(
        io:           StringIO.new(pdf_bytes),
        filename:     "change-order-#{change_order.number}.pdf",
        content_type: "application/pdf"
      )

      api_key = Rails.application.credentials.dropbox_sign&.api_key
      return Result.new(change_order: nil, error: "Dropbox Sign API key not configured") if api_key.blank?

      pdf_content = change_order.document_pdf.download

      config = Dropbox::Sign::Configuration.new
      config.username = api_key
      api_client      = Dropbox::Sign::ApiClient.new(config)
      signature_api   = Dropbox::Sign::SignatureRequestApi.new(api_client)

      signer = Dropbox::Sign::SubSignatureRequestSigner.new
      signer.email_address = work_order.client_contact_email
      signer.name          = work_order.client_display_name
      signer.order         = 0

      data          = Dropbox::Sign::SignatureRequestSendRequest.new
      data.title    = "Change Order #{change_order.number} — #{work_order.title}"
      data.signers  = [ signer ]
      data.metadata = { change_order_number: change_order.number, tenant_id: change_order.tenant_id }
      data.files    = [ pdf_content ]

      response   = signature_api.signature_request_send(data)
      request_id = response.signature_request.signature_request_id

      change_order.update!(
        dropbox_sign_request_id: request_id,
        status:                  :signature_sent
      )

      Result.new(change_order:, error: nil)
    rescue Dropbox::Sign::ApiError, ActiveRecord::RecordInvalid, Grover::JavaScript::Error => e
      Result.new(change_order: nil, error: e.message)
    end
  end
end
