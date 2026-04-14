require "rails_helper"

RSpec.describe DeleteSenderSignatureJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true) }
  let(:client) { instance_double(PostmarkClient) }
  let!(:sig) do
    SenderSignature.create!(
      tenant: tenant,
      external_id: 42,
      name: "Example Co.",
      email_address: "hello@example.com",
      confirmed: false,
      dkim_verified: false,
      spf_verified: false,
      return_path_domain_verified: false
    )
  end

  before do
    Current.tenant = tenant
    allow(PostmarkClient).to receive(:new).and_return(client)
  end

  context "when the API call succeeds" do
    before { allow(client).to receive(:delete_signature).with(42).and_return({ success: true, error: nil }) }

    it "destroys the local record" do
      expect {
        described_class.perform_now(sig.id)
      }.to change(SenderSignature, :count).by(-1)
    end

    it "broadcasts a remove targeting the signature row" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_remove_to).with(
        "sender_signatures_#{tenant.id}",
        target: "sender_signature_#{sig.id}"
      )

      described_class.perform_now(sig.id)
    end

    it "broadcasts a success flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "sender_signatures_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "notice", message: "Sender signature hello@example.com was deleted." }
      )

      described_class.perform_now(sig.id)
    end
  end

  context "when the API call fails" do
    before { allow(client).to receive(:delete_signature).and_return({ success: false, error: "Signature not found" }) }

    it "does not destroy the local record" do
      expect {
        described_class.perform_now(sig.id)
      }.not_to change(SenderSignature, :count)
    end

    it "broadcasts an error flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "sender_signatures_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "alert", message: "Failed to delete sender signature: Signature not found" }
      )

      described_class.perform_now(sig.id)
    end
  end
end
