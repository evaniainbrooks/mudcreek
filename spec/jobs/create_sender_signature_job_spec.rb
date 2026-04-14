require "rails_helper"

RSpec.describe CreateSenderSignatureJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true) }
  let(:client) { instance_double(PostmarkClient) }

  before do
    Current.tenant = tenant
    allow(PostmarkClient).to receive(:new).and_return(client)
  end

  context "when the API call succeeds" do
    let(:api_response) do
      {
        success: true,
        signature: {
          id: 42,
          name: "Example Co.",
          email_address: "hello@example.com",
          confirmed: false,
          dkim_verified: false,
          spf_verified: false,
          return_path_domain_verified: false
        },
        error: nil
      }
    end

    before { allow(client).to receive(:create_signature).with(from_email: "hello@example.com", name: "Example Co.").and_return(api_response) }

    it "creates a local SenderSignature record" do
      expect {
        described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")
      }.to change(SenderSignature, :count).by(1)
    end

    it "maps external_id, name, and email_address from the API response" do
      described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")

      record = SenderSignature.find_by!(external_id: 42)
      expect(record.name).to eq("Example Co.")
      expect(record.email_address).to eq("hello@example.com")
    end

    it "broadcasts the new signature row to the sender_signatures stream" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).with(
        "sender_signatures_#{tenant.id}",
        target: "sender-signatures-list",
        partial: "admin/sender_signatures/signature_row",
        locals: { sender_signature: instance_of(SenderSignature) }
      )

      described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")
    end

    it "broadcasts a success flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "sender_signatures_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "notice", message: "Sender signature hello@example.com was created. Check your inbox to confirm." }
      )

      described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")
    end
  end

  context "when the API call fails" do
    let(:api_response) { { success: false, signature: nil, error: "Invalid email address" } }

    before { allow(client).to receive(:create_signature).and_return(api_response) }

    it "does not create a local record" do
      expect {
        described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")
      }.not_to change(SenderSignature, :count)
    end

    it "broadcasts an error flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "sender_signatures_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "alert", message: "Failed to create sender signature: Invalid email address" }
      )

      described_class.perform_now(tenant.id, "hello@example.com", "Example Co.")
    end
  end
end
