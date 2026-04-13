require "rails_helper"

RSpec.describe CreateEmailAliasJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(ImprovmxClient) }

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(client)
  end

  context "when the API call succeeds" do
    let(:api_response) do
      { success: true, alias: { "id" => 42, "alias" => "hello", "forward" => "user@example.com" }, error: nil }
    end

    before { allow(client).to receive(:create_alias).with("example.com", "hello", "user@example.com").and_return(api_response) }

    it "creates a local EmailAlias record" do
      expect {
        described_class.perform_now(tenant.id, "hello", "user@example.com")
      }.to change(EmailAlias, :count).by(1)
    end

    it "maps external_id, alias, and forward from the API response" do
      described_class.perform_now(tenant.id, "hello", "user@example.com")

      record = EmailAlias.find_by!(external_id: 42)
      expect(record.alias).to eq("hello")
      expect(record.forward).to eq("user@example.com")
    end

    it "broadcasts the new alias row to the email_aliases stream" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).with(
        "email_aliases_#{tenant.id}",
        target: "email-aliases-list",
        partial: "admin/email_aliases/alias_row",
        locals: { email_alias: instance_of(EmailAlias) }
      )

      described_class.perform_now(tenant.id, "hello", "user@example.com")
    end

    it "broadcasts a success flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "email_aliases_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "notice", message: "Alias hello@example.com was created." }
      )

      described_class.perform_now(tenant.id, "hello", "user@example.com")
    end
  end

  context "when the API call fails" do
    let(:api_response) { { success: false, alias: nil, error: "Invalid forward address" } }

    before { allow(client).to receive(:create_alias).and_return(api_response) }

    it "does not create a local record" do
      expect {
        described_class.perform_now(tenant.id, "hello", "user@example.com")
      }.not_to change(EmailAlias, :count)
    end

    it "broadcasts an error flash message" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "email_aliases_#{tenant.id}",
        target: "flash",
        partial: "shared/flash_message",
        locals: { type: "alert", message: "Failed to create alias: Invalid forward address" }
      )

      described_class.perform_now(tenant.id, "hello", "user@example.com")
    end
  end
end
