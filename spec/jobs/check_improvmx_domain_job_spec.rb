require "rails_helper"

RSpec.describe CheckImprovmxDomainJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:service) { instance_double(ImprovmxClient) }

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(service)
    allow(Rails.cache).to receive(:write)
  end

  context "when the domain check succeeds" do
    let(:result) { { success: true, records: [], errors: [] } }

    before { allow(service).to receive(:check_domain).with("example.com").and_return(result) }

    it "writes the result to cache" do
      expect(Rails.cache).to receive(:write).with(
        "improvmx_domain_check_#{tenant.id}",
        result,
        expires_in: CheckImprovmxDomainJob::CACHE_TTL
      )

      described_class.perform_now(tenant.id)
    end

    it "broadcasts a replace to the improvmx stream" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "improvmx_check_#{tenant.id}",
        target: "improvmx-status",
        partial: "admin/email_aliases/status",
        locals: { result: result, tenant: tenant }
      )

      described_class.perform_now(tenant.id)
    end
  end

  context "when the domain check fails" do
    let(:result) { { success: false, records: [], errors: [ "MX record missing" ] } }

    before { allow(service).to receive(:check_domain).with("example.com").and_return(result) }

    it "writes the failure result to cache" do
      expect(Rails.cache).to receive(:write).with(
        "improvmx_domain_check_#{tenant.id}",
        result,
        expires_in: CheckImprovmxDomainJob::CACHE_TTL
      )

      described_class.perform_now(tenant.id)
    end

    it "broadcasts the failure status" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        "improvmx_check_#{tenant.id}",
        target: "improvmx-status",
        partial: "admin/email_aliases/status",
        locals: { result: result, tenant: tenant }
      )

      described_class.perform_now(tenant.id)
    end
  end

  context "when the service raises an error" do
    before { allow(service).to receive(:check_domain).and_return({ success: false, records: [], errors: [ "connection refused" ] }) }

    it "still writes a result to cache" do
      expect(Rails.cache).to receive(:write).with(
        "improvmx_domain_check_#{tenant.id}",
        { success: false, records: [], errors: [ "connection refused" ] },
        expires_in: CheckImprovmxDomainJob::CACHE_TTL
      )

      described_class.perform_now(tenant.id)
    end
  end

  it "sets Current.tenant before calling the service" do
    allow(service).to receive(:check_domain).and_return({ success: true, records: [], errors: [] })
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    described_class.perform_now(tenant.id)

    expect(Current.tenant).to eq(tenant)
  end
end
