require "rails_helper"

RSpec.describe CheckImprovmxDomainJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(ImprovmxClient) }
  let!(:domain) { Improvmx::Domain.create!(tenant: tenant, api_response: {}) }

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(client)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  context "when the domain check succeeds" do
    let(:result) { { success: true, records: [], errors: [] } }

    before { allow(client).to receive(:check_domain).with("example.com").and_return(result) }

    it "sets the domain status to verified" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.status).to eq("verified")
    end

    it "persists the check_data on the domain" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.check_data).to include("success" => true)
    end

    it "enqueues SyncEmailAliasesJob" do
      expect { described_class.perform_now(tenant.id) }.to have_enqueued_job(SyncEmailAliasesJob).with(tenant.id)
    end

    it "broadcasts a replace to the improvmx stream" do
      described_class.perform_now(tenant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "improvmx_check_#{tenant.id}",
        target: "improvmx-status",
        partial: "admin/email_aliases/status",
        locals: { domain: domain, checking: false }
      )
    end
  end

  context "when the domain check fails" do
    let(:result) { { success: false, records: [], errors: ["MX record missing"] } }

    before { allow(client).to receive(:check_domain).with("example.com").and_return(result) }

    it "sets the domain status to failed" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.status).to eq("failed")
    end

    it "persists the check_data on the domain" do
      described_class.perform_now(tenant.id)

      expect(domain.reload.check_data["errors"]).to include("MX record missing")
    end

    it "does not enqueue SyncEmailAliasesJob" do
      expect { described_class.perform_now(tenant.id) }.not_to have_enqueued_job(SyncEmailAliasesJob)
    end

    it "broadcasts the invalid status" do
      described_class.perform_now(tenant.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "improvmx_check_#{tenant.id}",
        target: "improvmx-status",
        partial: "admin/email_aliases/status",
        locals: { domain: domain, checking: false }
      )
    end
  end

  it "sets Current.tenant before calling the client" do
    allow(client).to receive(:check_domain).and_return({ success: true, records: [], errors: [] })

    described_class.perform_now(tenant.id)

    expect(Current.tenant).to eq(tenant)
  end

  it "raises if no Improvmx::Domain record exists for the tenant" do
    domain.destroy
    allow(client).to receive(:check_domain).and_return({ success: true, records: [], errors: [] })

    expect { described_class.perform_now(tenant.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
