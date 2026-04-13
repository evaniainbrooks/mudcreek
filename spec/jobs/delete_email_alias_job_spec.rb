require "rails_helper"

RSpec.describe DeleteEmailAliasJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(ImprovmxClient) }
  let!(:email_alias) do
    EmailAlias.create!(
      tenant: tenant,
      external_id: 42,
      alias: "hello",
      forward: "user@example.com"
    )
  end

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(client)
  end

  context "when the API call succeeds" do
    before { allow(client).to receive(:delete_alias).with("example.com", "hello").and_return({ success: true, error: nil }) }

    it "destroys the local record" do
      expect {
        described_class.perform_now(email_alias.id)
      }.to change(EmailAlias, :count).by(-1)
    end

    it "broadcasts a remove targeting the alias row" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_remove_to).with(
        "email_aliases_#{tenant.id}",
        target: "email_alias_#{email_alias.id}"
      )

      described_class.perform_now(email_alias.id)
    end

    it "broadcasts a success flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "email_aliases_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "notice", message: "Alias hello@example.com was deleted." }
      )

      described_class.perform_now(email_alias.id)
    end
  end

  context "when the API call fails" do
    before { allow(client).to receive(:delete_alias).and_return({ success: false, error: "Alias not found" }) }

    it "does not destroy the local record" do
      expect {
        described_class.perform_now(email_alias.id)
      }.not_to change(EmailAlias, :count)
    end

    it "broadcasts an error flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "email_aliases_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "alert", message: "Failed to delete alias: Alias not found" }
      )

      described_class.perform_now(email_alias.id)
    end
  end
end
