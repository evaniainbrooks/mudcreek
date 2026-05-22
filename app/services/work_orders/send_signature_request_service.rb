module WorkOrders
  class SendSignatureRequestService
    Result = Data.define(:work_order, :error) do
      def success? = error.nil?
    end

    def self.call(work_order:)
      api_key = Rails.application.credentials.dropbox_sign&.api_key
      return Result.new(work_order: nil, error: "Dropbox Sign API key not configured") if api_key.blank?

      return Result.new(work_order: nil, error: "Estimate PDF not attached") unless work_order.estimate_pdf.attached?

      pdf_content = work_order.estimate_pdf.download

      config = Dropbox::Sign::Configuration.new
      config.username = api_key
      api_client = Dropbox::Sign::ApiClient.new(config)
      signature_api = Dropbox::Sign::SignatureRequestApi.new(api_client)

      signer = Dropbox::Sign::SubSignatureRequestSigner.new
      signer.email_address = work_order.client_contact_email
      signer.name          = work_order.client_display_name
      signer.order         = 0

      data = Dropbox::Sign::SignatureRequestSendRequest.new
      data.title    = "Work Order #{work_order.number} — #{work_order.title}"
      data.signers  = [ signer ]
      data.metadata = { work_order_number: work_order.number, tenant_id: work_order.tenant_id }
      data.files    = [ pdf_content ]

      response = signature_api.signature_request_send(data)
      request_id = response.signature_request.signature_request_id

      work_order.update!(dropbox_sign_request_id: request_id)

      Result.new(work_order:, error: nil)
    rescue Dropbox::Sign::ApiError => e
      Result.new(work_order: nil, error: e.message)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(work_order: nil, error: e.message)
    end
  end
end
