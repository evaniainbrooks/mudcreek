module Admin
  class SenderSignaturesController < Admin::BaseController
    def index
      authorize(SenderSignature, policy_class: SenderSignaturePolicy)
      @signatures = SenderSignature.order(:email_address)
    end

    def create
      authorize(SenderSignature, :create?, policy_class: SenderSignaturePolicy)
      CreateSenderSignatureJob.perform_later(
        Current.tenant.id,
        params.require(:sender_signature).fetch(:email_address),
        params.require(:sender_signature).fetch(:name)
      )
      redirect_to admin_sender_signatures_path, notice: "Your request to add the sender signature is being processed."
    end

    def destroy
      @signature = SenderSignature.find(params[:id])
      authorize(@signature)
      DeleteSenderSignatureJob.perform_later(@signature.id)
      redirect_to admin_sender_signatures_path, notice: "Your request to delete the sender signature is being processed."
    end
  end
end
