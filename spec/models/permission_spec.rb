require "rails_helper"

RSpec.describe Permission, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "constants" do
    it "includes Listings::RentalRatePlan in RESOURCES" do
      expect(Permission::RESOURCES).to include("Listings::RentalRatePlan")
    end
  end

  describe "validations" do
    it "accepts a valid resource and action" do
      permission = build(:permission, resource: "Listing", action: "index")

      expect(permission).to be_valid
    end

    it "rejects an unknown resource" do
      permission = build(:permission, resource: "Unknown")

      expect(permission).not_to be_valid
      expect(permission.errors[:resource]).to be_present
    end

    it "rejects an unknown action" do
      permission = build(:permission, action: "hack")

      expect(permission).not_to be_valid
      expect(permission.errors[:action]).to be_present
    end

    it "rejects duplicate resource/action per role" do
      role = create(:role)
      create(:permission, role: role, resource: "Listing", action: "index")
      duplicate = build(:permission, role: role, resource: "Listing", action: "index")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:action]).to be_present
    end

    it "allows the same action on different resources for the same role" do
      role = create(:role)
      create(:permission, role: role, resource: "Listing", action: "index")
      other = build(:permission, role: role, resource: "Lot", action: "index")

      expect(other).to be_valid
    end
  end

  describe "immutability" do
    it "cannot be updated after creation" do
      permission = create(:permission)
      permission.action = "destroy"

      expect(permission).not_to be_valid
      expect(permission.errors[:base]).to include("Permissions cannot be modified after creation")
    end
  end
end
