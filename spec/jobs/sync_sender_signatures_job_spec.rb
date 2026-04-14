require "rails_helper"

RSpec.describe SyncSenderSignaturesJob, type: :job do
  let(:tenant) { Tenant.create!(key: "test", name: "Test", default: true) }
  let(:client) { instance_double(PostmarkClient) }

  before do
    Current.tenant = tenant
    allow(PostmarkClient).to receive(:new).and_return(client)
  end

  let(:remote_signatures) do
    [
      { id: 1, name: "Example Co.", email_address: "hello@example.com", confirmed: true, dkim_verified: true, spf_verified: true, return_path_domain_verified: true },
      { id: 2, name: "Support",     email_address: "support@example.com", confirmed: false, dkim_verified: false, spf_verified: false, return_path_domain_verified: false }
    ]
  end

  before { allow(client).to receive(:list_signatures).and_return(remote_signatures) }

  it "creates new local records from remote" do
    expect {
      described_class.perform_now(tenant.id)
    }.to change(SenderSignature, :count).by(2)
  end

  it "updates existing records with remote data" do
    sig = SenderSignature.create!(
      tenant: tenant,
      external_id: 1,
      name: "Old Name",
      email_address: "hello@example.com",
      confirmed: false,
      dkim_verified: false,
      spf_verified: false,
      return_path_domain_verified: false
    )

    described_class.perform_now(tenant.id)

    expect(sig.reload.name).to eq("Example Co.")
    expect(sig.reload.confirmed).to be(true)
  end

  it "removes stale local records not in remote" do
    stale = SenderSignature.create!(
      tenant: tenant,
      external_id: 99,
      name: "Stale",
      email_address: "stale@example.com",
      confirmed: false,
      dkim_verified: false,
      spf_verified: false,
      return_path_domain_verified: false
    )

    described_class.perform_now(tenant.id)

    expect(SenderSignature.exists?(stale.id)).to be(false)
  end
end
