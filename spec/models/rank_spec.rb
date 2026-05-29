require "rails_helper"

RSpec.describe Rank, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:discipline) }
    it { is_expected.to have_many(:rank_awards).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:position) }

    it "enforces name uniqueness within a discipline" do
      discipline = create(:discipline)
      create(:rank, discipline: discipline, name: "White Belt")
      dupe = build(:rank, discipline: discipline, name: "White Belt")
      expect(dupe).not_to be_valid
      expect(dupe.errors[:name]).to be_present
    end

    it "allows the same name in a different discipline" do
      create(:rank, name: "Beginner")
      expect(build(:rank, name: "Beginner")).to be_valid
    end
  end

  describe ".ordered" do
    it "orders by position" do
      d = create(:discipline)
      r2 = create(:rank, discipline: d, position: 2)
      r1 = create(:rank, discipline: d, position: 1)
      expect(Rank.ordered.to_a).to eq([r1, r2])
    end
  end
end
