require "rails_helper"

RSpec.describe NavbarItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:path) }

    it "requires a non-negative integer position" do
      item = build(:navbar_item, position: -1)
      expect(item).not_to be_valid
      expect(item.errors[:position]).to be_present
    end

    it "accepts position 0" do
      expect(build(:navbar_item, position: 0)).to be_valid
    end
  end

  describe ".ordered" do
    it "orders by position then id" do
      b = create(:navbar_item, position: 2)
      a = create(:navbar_item, position: 1)
      expect(NavbarItem.ordered.to_a).to eq([a, b])
    end
  end
end
