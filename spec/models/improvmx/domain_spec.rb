require "rails_helper"

RSpec.describe Improvmx::Domain, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:improvmx_domain)).to be_valid
    end

    it "enforces one record per tenant" do
      create(:improvmx_domain)
      expect(build(:improvmx_domain)).not_to be_valid
    end
  end

  describe "status enum" do
    it "defaults to unchecked" do
      domain = build(:improvmx_domain)
      expect(domain.status).to eq("unchecked")
    end

    it "accepts verified status" do
      domain = build(:improvmx_domain, status: :verified)
      expect(domain.status).to eq("verified")
    end

    it "accepts failed status" do
      domain = build(:improvmx_domain, status: :failed)
      expect(domain.status).to eq("failed")
    end
  end

  describe "multi-tenancy" do
    it "scopes records to the current tenant" do
      record = create(:improvmx_domain)
      Current.tenant = create(:tenant)
      expect(Improvmx::Domain.all).not_to include(record)
    end
  end
end
