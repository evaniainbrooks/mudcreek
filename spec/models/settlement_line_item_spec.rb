require "rails_helper"

RSpec.describe SettlementLineItem, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:lot)        { create(:lot) }
  let(:settlement) { Settlement.create!(lot: lot) }

  describe "associations" do
    it { is_expected.to belong_to(:settlement) }
    it { is_expected.to belong_to(:listing).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:line_item_type) }
  end

  describe "line_item_type enum" do
    %i[hammer_price buyers_premium tax seller_commission seller_fee].each do |type|
      it "accepts #{type}" do
        item = SettlementLineItem.new(settlement: settlement, description: "Test", amount_cents: 100, line_item_type: type)
        expect(item).to be_valid
      end
    end
  end

  describe "#currency" do
    it "delegates to the settlement lot" do
      item = SettlementLineItem.new(settlement: settlement)
      expect(item.currency).to eq(lot.currency)
    end
  end
end
