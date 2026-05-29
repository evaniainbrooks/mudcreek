require "rails_helper"

RSpec.describe RankAward, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:rank) }
    it { is_expected.to belong_to(:rankable) }
    it { is_expected.to belong_to(:awarded_by).optional.class_name("User") }
    it { is_expected.to have_one(:discipline).through(:rank) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:awarded_at) }

    it "accepts stripes from 0 to 4" do
      (0..4).each do |n|
        expect(build(:rank_award, stripes: n)).to be_valid
      end
    end

    it "rejects stripes outside 0–4" do
      expect(build(:rank_award, stripes: -1)).not_to be_valid
      expect(build(:rank_award, stripes: 5)).not_to be_valid
    end
  end

  describe "rankable_type_matches_discipline" do
    context "when discipline is for kids" do
      let(:discipline) { create(:discipline, kids: true) }
      let(:rank)       { create(:rank, discipline: discipline) }

      it "rejects a User rankable" do
        award = build(:rank_award, rank: rank, rankable: create(:user))
        expect(award).not_to be_valid
        expect(award.errors[:base]).to be_present
      end

      it "accepts a Kid rankable" do
        award = build(:rank_award, rank: rank, rankable: create(:kid))
        expect(award).to be_valid
      end
    end

    context "when discipline is not for kids" do
      let(:discipline) { create(:discipline, kids: false) }
      let(:rank)       { create(:rank, discipline: discipline) }

      it "accepts a User rankable" do
        award = build(:rank_award, rank: rank, rankable: create(:user))
        expect(award).to be_valid
      end

      it "rejects a Kid rankable" do
        award = build(:rank_award, rank: rank, rankable: create(:kid))
        expect(award).not_to be_valid
        expect(award.errors[:base]).to be_present
      end
    end
  end

  describe ".ordered" do
    it "orders by awarded_at descending" do
      old_award = create(:rank_award, awarded_at: 2.weeks.ago)
      new_award = create(:rank_award, awarded_at: 1.week.ago)
      expect(RankAward.ordered.first).to eq(new_award)
      expect(RankAward.ordered.last).to eq(old_award)
    end
  end
end
