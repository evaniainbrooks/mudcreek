require "rails_helper"

RSpec.describe WorkOrderItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order) }

  describe "associations" do
    it { is_expected.to belong_to(:work_order) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "requires a positive integer quantity" do
      item = build(:work_order_item, work_order:, quantity: 0)
      expect(item).not_to be_valid
      expect(item.errors[:quantity]).to be_present
    end

    it "rejects a negative quantity" do
      item = build(:work_order_item, work_order:, quantity: -1)
      expect(item).not_to be_valid
    end

    it "requires a non-negative unit price" do
      item = build(:work_order_item, work_order:, unit_price_cents: -1)
      expect(item).not_to be_valid
      expect(item.errors[:unit_price_cents]).to be_present
    end

    it "accepts a zero unit price" do
      item = build(:work_order_item, work_order:, unit_price_cents: 0)
      expect(item).to be_valid
    end
  end

  describe "monetization" do
    let(:item) { build(:work_order_item, work_order:, quantity: 3, unit_price_cents: 10_000) }

    it "exposes unit_price as a Money object" do
      expect(item.unit_price).to be_a(Money)
      expect(item.unit_price.fractional).to eq(10_000)
    end

    it "exposes line_total as a Money object" do
      expect(item.line_total).to be_a(Money)
      expect(item.line_total.fractional).to eq(30_000)
    end
  end

  describe "#line_total_cents" do
    it "returns quantity × unit_price_cents" do
      item = build(:work_order_item, work_order:, quantity: 4, unit_price_cents: 2_500)
      expect(item.line_total_cents).to eq(10_000)
    end
  end

  describe "ordering" do
    it "is ordered by position via acts_as_list" do
      wo    = create(:work_order)
      item2 = create(:work_order_item, work_order: wo, name: "Second")
      item1 = create(:work_order_item, work_order: wo, name: "First")
      item1.move_to_top

      expect(wo.work_order_items.reload.map(&:name)).to eq(["First", "Second"])
    end
  end
end
