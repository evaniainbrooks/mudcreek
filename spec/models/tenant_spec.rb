require "rails_helper"

RSpec.describe Tenant, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:key) }

    it "rejects a key with uppercase letters" do
      tenant = build(:tenant, key: "MyTenant")

      expect(tenant).not_to be_valid
      expect(tenant.errors[:key]).to be_present
    end

    it "rejects a key with spaces" do
      tenant = build(:tenant, key: "my tenant")

      expect(tenant).not_to be_valid
    end

    it "accepts a key with lowercase letters, digits, and underscores" do
      tenant = build(:tenant, key: "my_tenant_1")

      expect(tenant).to be_valid
    end

    it "rejects duplicate keys" do
      create(:tenant, key: "acme")
      duplicate = build(:tenant, key: "acme")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to be_present
    end

    it "only allows one default tenant" do
      create(:tenant, default: true)
      second = build(:tenant, default: true)

      expect(second).not_to be_valid
      expect(second.errors[:default]).to be_present
    end

    it "allows multiple non-default tenants" do
      create(:tenant, default: false)
      second = build(:tenant, default: false)

      expect(second).to be_valid
    end
  end

  describe ".default" do
    it "returns the tenant marked as default" do
      tenant = create(:tenant, default: true)

      expect(Tenant.default).to eq(tenant)
    end

    it "raises when no default tenant exists" do
      expect { Tenant.default }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
