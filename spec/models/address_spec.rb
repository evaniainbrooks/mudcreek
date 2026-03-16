require "rails_helper"

RSpec.describe Address, type: :model do
  let(:tenant) { create(:tenant) }
  subject(:address) { Address.new(addressable: tenant) }

  describe "associations" do
    it { is_expected.to belong_to(:addressable) }
  end

  describe "validations" do
    it "rejects an unrecognised country code" do
      address.country = "ZZ"
      expect(address).not_to be_valid
      expect(address.errors[:country]).to be_present
    end

    it "accepts a valid ISO 3166-1 alpha-2 country code" do
      address.country = "CA"
      expect(address).to be_valid
    end

    it "accepts a blank country" do
      address.country = ""
      expect(address).to be_valid
    end

    it "enforces uniqueness of address_type per addressable" do
      Address.create!(addressable: tenant, address_type: "billing")
      duplicate = Address.new(addressable: tenant, address_type: "billing")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:address_type]).to be_present
    end

    it "allows the same address_type for different addressables" do
      other_tenant = create(:tenant, key: "other", default: false)
      Address.create!(addressable: tenant, address_type: "billing")
      second = Address.new(addressable: other_tenant, address_type: "billing")
      expect(second).to be_valid
    end
  end

  describe "#any?" do
    it "returns false when all fields are blank" do
      expect(address.any?).to be false
    end

    it "returns true when at least one field is present" do
      address.city = "Calgary"
      expect(address.any?).to be true
    end
  end

  describe "#to_fs" do
    before do
      address.street_address = "123 Main St"
      address.city           = "Calgary"
      address.province       = "AB"
      address.postal_code    = "T2P 1J9"
      address.country        = "CA"
    end

    it "joins the first 3 components for the short format" do
      expect(address.to_fs(:short)).to eq("123 Main St, Calgary, AB")
    end

    it "joins all components for the long format" do
      expect(address.to_fs(:long)).to eq("123 Main St, Calgary, AB, T2P 1J9, CA")
    end

    it "omits blank components" do
      address.postal_code = nil
      expect(address.to_fs(:long)).to eq("123 Main St, Calgary, AB, CA")
    end
  end
end
