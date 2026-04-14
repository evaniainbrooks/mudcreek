require "rails_helper"

RSpec.describe ProvisionPostmarkDomainJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(PostmarkClient) }

  let(:domain_data) { { "id" => 8139, "name" => "example.com", "dkim_verified" => false } }

  before do
    Current.tenant = tenant
    allow(PostmarkClient).to receive(:new).and_return(client)
  end

  context "when the domain already exists in Postmark" do
    before do
      allow(client).to receive(:find_domain_by_name).with("example.com").and_return(domain_data)
    end

    it "creates a Postmark::Domain record" do
      expect { described_class.perform_now(tenant.id) }.to change(Postmark::Domain, :count).by(1)
    end

    it "stores the external_id from the API response" do
      described_class.perform_now(tenant.id)

      expect(Postmark::Domain.find_by(tenant: tenant).external_id).to eq(8139)
    end

    it "stores the api_response" do
      described_class.perform_now(tenant.id)

      expect(Postmark::Domain.find_by(tenant: tenant).api_response).to eq(domain_data)
    end

    it "does not call create_domain" do
      expect(client).not_to receive(:create_domain)

      described_class.perform_now(tenant.id)
    end
  end

  context "when the domain does not exist in Postmark" do
    let(:created_data) { { "id" => 9999, "name" => "example.com", "dkim_verified" => false } }

    before do
      allow(client).to receive(:find_domain_by_name).with("example.com").and_return(nil)
      allow(client).to receive(:create_domain).with("example.com").and_return({ success: true, domain: created_data, error: nil })
    end

    it "creates a Postmark::Domain record" do
      expect { described_class.perform_now(tenant.id) }.to change(Postmark::Domain, :count).by(1)
    end

    it "stores the external_id from the created domain" do
      described_class.perform_now(tenant.id)

      expect(Postmark::Domain.find_by(tenant: tenant).external_id).to eq(9999)
    end

    it "stores the api_response" do
      described_class.perform_now(tenant.id)

      expect(Postmark::Domain.find_by(tenant: tenant).api_response).to eq(created_data)
    end
  end

  context "when both find and create fail" do
    before do
      allow(client).to receive(:find_domain_by_name).with("example.com").and_return(nil)
      allow(client).to receive(:create_domain).with("example.com").and_return({ success: false, domain: nil, error: "server error" })
    end

    it "does not create a record" do
      expect { described_class.perform_now(tenant.id) }.not_to change(Postmark::Domain, :count)
    end
  end

  context "when a record already exists (idempotency)" do
    let!(:existing) { Postmark::Domain.create!(tenant: tenant, external_id: 8139, api_response: { "name" => "example.com" }) }
    let(:updated_data) { { "id" => 8139, "name" => "example.com", "dkim_verified" => true } }

    before do
      allow(client).to receive(:find_domain_by_name).with("example.com").and_return(updated_data)
    end

    it "does not create a second record" do
      expect { described_class.perform_now(tenant.id) }.not_to change(Postmark::Domain, :count)
    end

    it "updates the existing record's api_response" do
      described_class.perform_now(tenant.id)

      expect(existing.reload.api_response).to eq(updated_data)
    end
  end
end
