require "rails_helper"

RSpec.describe Discipline, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to have_many(:ranks).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "enforces name uniqueness within a tenant" do
      create(:discipline, name: "Jiu-Jitsu")
      dupe = build(:discipline, name: "Jiu-Jitsu")
      expect(dupe).not_to be_valid
      expect(dupe.errors[:name]).to be_present
    end

    it "allows the same name under a different tenant" do
      create(:discipline, name: "Jiu-Jitsu")
      Current.tenant = create(:tenant)
      expect(build(:discipline, name: "Jiu-Jitsu")).to be_valid
    end
  end

  describe ".ordered" do
    it "orders by name" do
      z = create(:discipline, name: "Zumba")
      a = create(:discipline, name: "Archery")
      expect(Discipline.ordered.to_a).to eq([a, z])
    end
  end
end
