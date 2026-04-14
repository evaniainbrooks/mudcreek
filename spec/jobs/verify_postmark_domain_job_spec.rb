require "rails_helper"

RSpec.describe VerifyPostmarkDomainJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(PostmarkClient) }
  let!(:domain) { Postmark::Domain.create!(tenant: tenant, external_id: 8139, api_response: { "name" => "example.com" }) }

  before do
    Current.tenant = tenant
    allow(PostmarkClient).to receive(:new).and_return(client)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  context "when DKIM verification succeeds" do
    let(:updated_data) { { "id" => 8139, "name" => "example.com", "dkim_verified" => true, "return_path_domain_verified" => true } }

    before do
      allow(client).to receive(:verify_domain).with(8139).and_return({ success: true, domain: updated_data, error: nil })
    end

    it "sets the domain status to verified" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.status).to eq("verified")
    end

    it "updates the api_response" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.api_response).to eq(updated_data)
    end

    it "broadcasts a replace with the updated domain" do
      described_class.perform_now(tenant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "postmark_domain_#{tenant.id}",
        target: "postmark-domain-status",
        partial: "admin/sender_signatures/domain_status",
        locals: { domain: domain, checking: false }
      )
    end
  end

  context "when DKIM verification fails" do
    let(:updated_data) { { "id" => 8139, "name" => "example.com", "dkim_verified" => false } }

    before do
      allow(client).to receive(:verify_domain).with(8139).and_return({ success: false, domain: updated_data, error: nil })
    end

    it "sets the domain status to failed" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.status).to eq("failed")
    end

    it "updates the api_response" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.api_response).to eq(updated_data)
    end

    it "broadcasts the failed status" do
      described_class.perform_now(tenant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "postmark_domain_#{tenant.id}",
        target: "postmark-domain-status",
        partial: "admin/sender_signatures/domain_status",
        locals: { domain: domain, checking: false }
      )
    end
  end

  context "when the API call itself fails" do
    before do
      allow(client).to receive(:verify_domain).with(8139).and_return({ success: false, domain: nil, error: "connection refused" })
    end

    it "sets the domain status to failed" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.status).to eq("failed")
    end

    it "preserves the existing api_response" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.api_response).to eq({ "name" => "example.com" })
    end
  end

  it "raises if no Postmark::Domain record exists for the tenant" do
    domain.destroy
    allow(client).to receive(:verify_domain).and_return({ success: true, domain: {}, error: nil })

    expect { described_class.perform_now(tenant.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
