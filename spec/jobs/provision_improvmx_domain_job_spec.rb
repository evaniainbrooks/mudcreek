require "rails_helper"

RSpec.describe ProvisionImprovmxDomainJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(ImprovmxClient) }

  let(:domain_payload) { { "domain" => "example.com", "active" => true, "display" => "example.com" } }

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(client)
  end

  context "when the domain already exists in ImprovMX" do
    before do
      allow(client).to receive(:get_domain).with("example.com").and_return({ success: true, domain: domain_payload })
    end

    it "creates an Improvmx::Domain record" do
      expect { described_class.perform_now(tenant.id) }.to change(Improvmx::Domain, :count).by(1)
    end

    it "stores the API response" do
      described_class.perform_now(tenant.id)

      expect(Improvmx::Domain.find_by(tenant: tenant).api_response).to eq(domain_payload)
    end

    it "does not call create_domain" do
      expect(client).not_to receive(:create_domain)

      described_class.perform_now(tenant.id)
    end
  end

  context "when the domain does not exist in ImprovMX" do
    let(:created_payload) { { "domain" => "example.com", "active" => false } }

    before do
      allow(client).to receive(:get_domain).with("example.com").and_return({ success: false, domain: nil })
      allow(client).to receive(:create_domain).with("example.com").and_return({ success: true, domain: created_payload, error: nil })
    end

    it "creates an Improvmx::Domain record" do
      expect { described_class.perform_now(tenant.id) }.to change(Improvmx::Domain, :count).by(1)
    end

    it "stores the created domain API response" do
      described_class.perform_now(tenant.id)

      expect(Improvmx::Domain.find_by(tenant: tenant).api_response).to eq(created_payload)
    end
  end

  context "when the domain exists remotely but has an empty domain body" do
    before do
      allow(client).to receive(:get_domain).with("example.com").and_return({ success: true, domain: nil })
      allow(client).to receive(:create_domain).with("example.com").and_return({ success: true, domain: domain_payload, error: nil })
    end

    it "falls through to create_domain" do
      described_class.perform_now(tenant.id)

      expect(Improvmx::Domain.find_by(tenant: tenant).api_response).to eq(domain_payload)
    end
  end

  context "when both get and create return no domain payload" do
    before do
      allow(client).to receive(:get_domain).and_return({ success: false, domain: nil })
      allow(client).to receive(:create_domain).and_return({ success: false, domain: nil, error: "server error" })
    end

    it "does not create a record" do
      expect { described_class.perform_now(tenant.id) }.not_to change(Improvmx::Domain, :count)
    end
  end

  context "when a record already exists (idempotency)" do
    let!(:existing) do
      Improvmx::Domain.create!(tenant: tenant, api_response: { "domain" => "example.com", "active" => false })
    end
    let(:updated_payload) { { "domain" => "example.com", "active" => true } }

    before do
      allow(client).to receive(:get_domain).with("example.com").and_return({ success: true, domain: updated_payload })
    end

    it "does not create a second record" do
      expect { described_class.perform_now(tenant.id) }.not_to change(Improvmx::Domain, :count)
    end

    it "updates the existing record's api_response" do
      described_class.perform_now(tenant.id)

      expect(existing.reload.api_response).to eq(updated_payload)
    end
  end
end
