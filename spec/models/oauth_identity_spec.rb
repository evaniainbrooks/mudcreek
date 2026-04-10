require "rails_helper"

RSpec.describe OauthIdentity, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "requires provider" do
      identity = build(:oauth_identity, provider: "")
      expect(identity).not_to be_valid
      expect(identity.errors[:provider]).to be_present
    end

    it "requires uid" do
      identity = build(:oauth_identity, uid: "")
      expect(identity).not_to be_valid
      expect(identity.errors[:uid]).to be_present
    end

    it "enforces uniqueness of provider + uid" do
      create(:oauth_identity, provider: "google", uid: "abc123")
      duplicate = build(:oauth_identity, provider: "google", uid: "abc123")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:provider]).to be_present
    end

    it "allows the same uid for different providers" do
      create(:oauth_identity, provider: "google", uid: "abc123")
      other = build(:oauth_identity, provider: "facebook", uid: "abc123")
      expect(other).to be_valid
    end
  end
end
