require "rails_helper"

RSpec.describe QrCode, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:destination_url) }

    it "requires slug" do
      qr = build(:qr_code, slug: "")
      qr.name = "" # prevent auto-derive
      expect(qr).not_to be_valid
    end

    it "rejects slugs with uppercase letters" do
      qr = QrCode.new(name: "Test", slug: "Bad-Slug", destination_url: "https://example.com", active: true)
      expect(qr).not_to be_valid
      expect(qr.errors[:slug]).to be_present
    end

    it "rejects slugs with spaces" do
      qr = QrCode.new(name: "Test", slug: "bad slug", destination_url: "https://example.com", active: true)
      expect(qr).not_to be_valid
    end

    it "accepts a valid lowercase-hyphenated slug" do
      qr = build(:qr_code, slug: "my-qr-code")
      expect(qr).to be_valid
    end

    it "enforces slug uniqueness per tenant" do
      create(:qr_code, slug: "my-code")
      duplicate = build(:qr_code, slug: "my-code")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end
  end

  describe "slug auto-derivation" do
    it "derives slug from name on create when blank" do
      qr = QrCode.create!(name: "Summer Sale", destination_url: "https://example.com", active: true)
      expect(qr.slug).to eq("summer-sale")
    end

    it "does not overwrite an explicitly set slug" do
      qr = QrCode.create!(name: "Summer Sale", slug: "custom-slug",
                           destination_url: "https://example.com", active: true)
      expect(qr.slug).to eq("custom-slug")
    end
  end

  describe "#live?" do
    it "returns true when active and no expiry" do
      expect(build(:qr_code, active: true, expires_at: nil).live?).to be true
    end

    it "returns true when active and expiry is in the future" do
      expect(build(:qr_code, :with_expiry).live?).to be true
    end

    it "returns false when inactive" do
      expect(build(:qr_code, :inactive).live?).to be false
    end

    it "returns false when expired" do
      expect(build(:qr_code, :expired).live?).to be false
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      qr = create(:qr_code, slug: "my-code")
      expect(qr.to_param).to eq("my-code")
    end
  end
end
