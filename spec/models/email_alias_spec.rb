require "rails_helper"

RSpec.describe EmailAlias, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "is valid with required attributes" do
      expect(build(:email_alias)).to be_valid
    end

    it "requires external_id" do
      expect(build(:email_alias, external_id: nil)).not_to be_valid
    end

    it "requires alias" do
      expect(build(:email_alias, alias: nil)).not_to be_valid
    end

    it "requires forward" do
      expect(build(:email_alias, forward: nil)).not_to be_valid
    end

    it "enforces uniqueness of external_id scoped to tenant" do
      create(:email_alias, external_id: 42)
      expect(build(:email_alias, external_id: 42)).not_to be_valid
    end

    it "allows the same external_id for a different tenant" do
      create(:email_alias, external_id: 42)
      Current.tenant = create(:tenant)
      expect(build(:email_alias, external_id: 42)).to be_valid
    end
  end

  describe "multi-tenancy" do
    it "scopes records to the current tenant" do
      record = create(:email_alias)
      Current.tenant = create(:tenant)
      expect(EmailAlias.all).not_to include(record)
    end

    it "requires a tenant" do
      Current.tenant = nil
      expect(EmailAlias.new(external_id: 1, alias: "a@b.com", forward: "f@b.com")).not_to be_valid
    end
  end
end
