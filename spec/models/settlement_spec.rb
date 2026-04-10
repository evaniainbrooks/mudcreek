require "rails_helper"

RSpec.describe Settlement, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:lot)        { create(:lot) }
  let(:settlement) { Settlement.create!(lot: lot) }

  describe "validations" do
    it "enforces one settlement per lot" do
      settlement
      duplicate = Settlement.new(lot: lot)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:lot_id]).to be_present
    end
  end

  describe "#net_payout_cents" do
    it "returns hammer price minus commission and fees" do
      settlement.settlement_line_items.create!(description: "Hammer price",
        line_item_type: :hammer_price, amount_cents: 10_000)
      settlement.settlement_line_items.create!(description: "Commission",
        line_item_type: :seller_commission, amount_cents: 1_000)
      settlement.settlement_line_items.create!(description: "Fee",
        line_item_type: :seller_fee, amount_cents: 250)

      expect(settlement.net_payout_cents).to eq(8_750)
    end

    it "returns 0 when there are no line items" do
      expect(settlement.net_payout_cents).to eq(0)
    end
  end
end
