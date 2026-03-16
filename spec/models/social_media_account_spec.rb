require "rails_helper"

RSpec.describe SocialMediaAccount, type: :model do
  let(:tenant) { create(:tenant) }

  describe "associations" do
    it { is_expected.to belong_to(:tenant) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:platform) }
    it { is_expected.to validate_presence_of(:slug) }

    it "rejects a duplicate platform for the same tenant" do
      SocialMediaAccount.create!(tenant: tenant, platform: :instagram, slug: "acme")
      duplicate = SocialMediaAccount.new(tenant: tenant, platform: :instagram, slug: "other")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:platform]).to be_present
    end

    it "allows the same platform for different tenants" do
      other_tenant = create(:tenant, key: "other", default: false)
      SocialMediaAccount.create!(tenant: tenant, platform: :instagram, slug: "acme")
      account = SocialMediaAccount.new(tenant: other_tenant, platform: :instagram, slug: "acme2")
      expect(account).to be_valid
    end
  end

  describe "icon auto-set" do
    it "sets the icon from PLATFORM_ICONS before validation" do
      account = SocialMediaAccount.new(tenant: tenant, platform: :facebook, slug: "acmeco")
      account.valid?
      expect(account.icon).to eq("bi-facebook")
    end

    it "sets the correct icon for each platform" do
      SocialMediaAccount::PLATFORM_ICONS.each do |platform, expected_icon|
        account = SocialMediaAccount.new(tenant: tenant, platform: platform, slug: "acme")
        account.valid?
        expect(account.icon).to eq(expected_icon)
      end
    end

    it "does not overwrite an explicitly set icon" do
      account = SocialMediaAccount.new(tenant: tenant, platform: :instagram, slug: "acme", icon: "bi-custom")
      account.valid?
      expect(account.icon).to eq("bi-custom")
    end
  end
end
