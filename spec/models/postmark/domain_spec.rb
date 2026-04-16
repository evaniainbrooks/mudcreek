require "rails_helper"

RSpec.describe Postmark::Domain, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:postmark_domain)).to be_valid
    end

    it "requires external_id" do
      expect(build(:postmark_domain, external_id: nil)).not_to be_valid
    end

    it "enforces uniqueness of external_id" do
      create(:postmark_domain, external_id: 99)
      expect(build(:postmark_domain, external_id: 99)).not_to be_valid
    end

    it "enforces one record per tenant" do
      create(:postmark_domain)
      expect(build(:postmark_domain)).not_to be_valid
    end
  end

  describe "status enum" do
    it "defaults to unchecked" do
      domain = build(:postmark_domain)
      expect(domain.status).to eq("unchecked")
    end

    it "accepts verified status" do
      expect(build(:postmark_domain, status: :verified).status).to eq("verified")
    end

    it "accepts failed status" do
      expect(build(:postmark_domain, status: :failed).status).to eq("failed")
    end
  end

  describe "multi-tenancy" do
    it "scopes records to the current tenant" do
      record = create(:postmark_domain)
      Current.tenant = create(:tenant)
      expect(Postmark::Domain.all).not_to include(record)
    end
  end
end
