require "rails_helper"

RSpec.describe SyncEmailAliasesJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com") }
  let(:client) { instance_double(ImprovmxClient) }

  before do
    Current.tenant = tenant
    allow(ImprovmxClient).to receive(:new).and_return(client)
  end

  let(:remote_aliases) do
    [
      { "id" => 1, "alias" => "hello", "forward" => "user@example.com" },
      { "id" => 2, "alias" => "support", "forward" => "support@example.com" }
    ]
  end

  def create_alias(external_id:, **attrs)
    EmailAlias.create!(
      tenant: tenant,
      external_id: external_id,
      alias: attrs.fetch(:alias, "old"),
      forward: attrs.fetch(:forward, "old@example.com")
    )
  end

  context "when there are no existing local records" do
    before { allow(client).to receive(:list_aliases).with("example.com").and_return(remote_aliases) }

    it "creates a local record for each remote alias" do
      expect { described_class.perform_now(tenant.id) }.to change(EmailAlias, :count).by(2)
    end

    it "maps external_id, alias, and forward correctly" do
      described_class.perform_now(tenant.id)

      record = EmailAlias.find_by(external_id: 1)
      expect(record.alias).to eq("hello")
      expect(record.forward).to eq("user@example.com")
    end
  end

  context "when local records already exist" do
    before do
      create_alias(external_id: 1, alias: "hello", forward: "old@example.com")
      allow(client).to receive(:list_aliases).with("example.com").and_return(remote_aliases)
    end

    it "updates changed attributes on existing records" do
      described_class.perform_now(tenant.id)

      expect(EmailAlias.find_by(external_id: 1).forward).to eq("user@example.com")
    end

    it "creates records that are new in the remote" do
      expect { described_class.perform_now(tenant.id) }.to change(EmailAlias, :count).by(1)
    end
  end

  context "when a local record no longer exists remotely" do
    before do
      create_alias(external_id: 99, alias: "gone", forward: "gone@example.com")
      allow(client).to receive(:list_aliases).with("example.com").and_return(remote_aliases)
    end

    it "deletes the stale local record" do
      described_class.perform_now(tenant.id)

      expect(EmailAlias.find_by(external_id: 99)).to be_nil
    end
  end

  context "when nothing has changed" do
    before do
      create_alias(external_id: 1, alias: "hello", forward: "user@example.com")
      create_alias(external_id: 2, alias: "support", forward: "support@example.com")
      allow(client).to receive(:list_aliases).with("example.com").and_return(remote_aliases)
    end

    it "does not change the record count" do
      expect { described_class.perform_now(tenant.id) }.not_to change(EmailAlias, :count)
    end
  end

  it "acquires a per-tenant advisory lock scoped to :email_aliases" do
    allow(client).to receive(:list_aliases).and_return([])
    allow(Tenant).to receive(:find).with(tenant.id).and_return(tenant)
    expect(tenant).to receive(:with_advisory_lock).with("email_aliases").and_yield

    described_class.perform_now(tenant.id)
  end

  context "when the ImprovMX API returns no aliases" do
    before do
      create_alias(external_id: 1, alias: "hello", forward: "user@example.com")
      allow(client).to receive(:list_aliases).with("example.com").and_return([])
    end

    it "removes all local records" do
      described_class.perform_now(tenant.id)

      expect(EmailAlias.count).to eq(0)
    end
  end
end
