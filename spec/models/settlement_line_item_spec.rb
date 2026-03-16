require "rails_helper"

RSpec.describe SettlementLineItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:lot)        { create(:lot) }
  let(:settlement) { Settlement.create!(lot: lot) }

  def build_item(attrs = {})
    SettlementLineItem.new(
      { settlement: settlement, description: "Hammer price", amount_cents: 10_000, line_item_type: :hammer_price }.merge(attrs)
    )
  end

  describe "associations" do
    it "belongs to a settlement" do
      item = build_item
      item.save!
      expect(item.settlement).to eq(settlement)
    end

    it "optionally belongs to a listing" do
      item = build_item
      expect(item.listing).to be_nil
      item.save!
      expect(item).to be_persisted
    end
  end

  describe "validations" do
    it "requires description" do
      item = build_item(description: "")
      expect(item).not_to be_valid
      expect(item.errors[:description]).to be_present
    end

    it "requires amount_cents" do
      item = build_item(amount_cents: nil)
      expect(item).not_to be_valid
      expect(item.errors[:amount_cents]).to be_present
    end

    it "requires line_item_type" do
      item = SettlementLineItem.new(settlement: settlement, description: "Test", amount_cents: 100)
      expect(item).not_to be_valid
      expect(item.errors[:line_item_type]).to be_present
    end
  end

  describe "line_item_type enum" do
    %i[hammer_price buyers_premium tax seller_commission seller_fee].each do |type|
      it "accepts #{type}" do
        item = build_item(line_item_type: type)
        expect(item).to be_valid
      end
    end
  end

  describe "#currency" do
    it "delegates to the settlement lot" do
      item = build_item
      expect(item.currency).to eq(lot.currency)
    end
  end
end
