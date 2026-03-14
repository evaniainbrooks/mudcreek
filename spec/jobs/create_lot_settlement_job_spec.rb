require "rails_helper"

RSpec.describe CreateLotSettlementJob, type: :job do
  before do
    Current.tenant = create(:tenant, default: true)
  end

  # Build a lot-owned listing. Using `lot:` instead of `owner:` satisfies the
  # owner_or_lot_present DB constraint.
  let(:owner) { create(:user) }
  let(:lot)   { create(:lot, owner: owner) }
  let(:listing) { create(:listing, owner: nil, lot: lot, price_cents: 10_000) }

  def perform(sale_context = { hammer_price_cents: 10_000 })
    described_class.new.perform(listing.id, sale_context)
  end

  context "when the listing has no lot" do
    let(:listing) { create(:listing, price_cents: 10_000) }

    it "does nothing" do
      expect { perform }.not_to change(Settlement, :count)
    end
  end

  context "tenant setup" do
    it "sets Current.tenant from the listing before creating records" do
      listing_id = listing.id  # force creation while tenant is still set
      Current.tenant = nil

      expect {
        described_class.new.perform(listing_id, hammer_price_cents: 10_000)
      }.to change(Settlement, :count).by(1)

      expect(Settlement.unscoped.last.tenant_id).to be_present
    end
  end

  context "settlement creation" do
    it "creates a settlement for the lot" do
      expect { perform }.to change(Settlement, :count).by(1)
      expect(lot.reload.settlement).to be_present
    end

    it "reuses an existing settlement on subsequent calls" do
      perform
      expect { perform(hammer_price_cents: 5_000) }.not_to change(Settlement, :count)
    end

    it "creates a hammer_price line item" do
      perform(hammer_price_cents: 10_000)

      item = lot.settlement.settlement_line_items.find_by(line_item_type: :hammer_price)
      expect(item).to have_attributes(
        amount_cents: 10_000,
        description:  "Hammer price \u2014 #{listing.name}",
        listing:      listing
      )
    end
  end

  context "idempotency" do
    it "does not create duplicate line items when called twice for the same listing" do
      perform
      expect { perform }.not_to change(SettlementLineItem, :count)
    end
  end

  context "buyer's premium" do
    it "creates a buyers_premium line item when amount is > 0" do
      perform(hammer_price_cents: 10_000, buyers_premium_cents: 1_500)

      item = lot.settlement.settlement_line_items.find_by(line_item_type: :buyers_premium)
      expect(item).to have_attributes(amount_cents: 1_500)
    end

    it "does not create a buyers_premium line item when amount is 0" do
      perform(hammer_price_cents: 10_000, buyers_premium_cents: 0)

      expect(lot.settlement.settlement_line_items.where(line_item_type: :buyers_premium)).to be_empty
    end

    it "does not create a buyers_premium line item when omitted from sale_context" do
      perform(hammer_price_cents: 10_000)

      expect(lot.settlement.settlement_line_items.where(line_item_type: :buyers_premium)).to be_empty
    end
  end

  context "seller commission" do
    before { lot.update!(commission_rate: 15) }

    it "creates a seller_commission line item" do
      perform(hammer_price_cents: 10_000)

      item = lot.settlement.settlement_line_items.find_by(line_item_type: :seller_commission)
      expect(item).to have_attributes(
        amount_cents: 1_500,
        description:  "Commission (15%) \u2014 #{listing.name}"
      )
    end

    it "rounds commission to the nearest cent" do
      perform(hammer_price_cents: 10_001)

      item = lot.settlement.settlement_line_items.find_by(line_item_type: :seller_commission)
      expect(item.amount_cents).to eq((10_001 * 0.15).round)
    end
  end

  context "when the lot has no commission rate" do
    it "does not create a seller_commission line item" do
      lot.update!(commission_rate: nil)
      perform

      expect(lot.settlement.settlement_line_items.where(line_item_type: :seller_commission)).to be_empty
    end
  end

  context "seller fee" do
    before { lot.update!(seller_fee_cents: 2_000) }

    it "creates a seller_fee line item on the first sale" do
      perform

      item = lot.settlement.settlement_line_items.find_by(line_item_type: :seller_fee)
      expect(item).to have_attributes(
        amount_cents: 2_000,
        description:  "Seller fee \u2014 #{lot.name}"
      )
    end

    it "adds the seller_fee only once even when multiple listings are sold from the same lot" do
      second_listing = create(:listing, owner: nil, lot: lot, price_cents: 5_000)

      perform
      described_class.new.perform(second_listing.id, hammer_price_cents: 5_000)

      fee_count = lot.settlement.settlement_line_items.where(line_item_type: :seller_fee).count
      expect(fee_count).to eq(1)
    end
  end

  context "when the lot has no seller fee" do
    it "does not create a seller_fee line item" do
      lot.update!(seller_fee_cents: nil)
      perform

      expect(lot.settlement.settlement_line_items.where(line_item_type: :seller_fee)).to be_empty
    end
  end

  context "net payout calculation" do
    before do
      lot.update!(commission_rate: 10, seller_fee_cents: 1_000)
    end

    it "returns hammer price minus commission and seller fee" do
      perform(hammer_price_cents: 10_000, buyers_premium_cents: 1_500)

      settlement = lot.settlement
      # hammer=10_000, commission=1_000, seller_fee=1_000 → net=8_000
      # buyers_premium is not deducted (buyer cost)
      expect(settlement.net_payout_cents).to eq(8_000)
    end
  end

  context "mailer" do
    it "delivers a settlement_updated email" do
      expect { perform }
        .to have_enqueued_mail(LotMailer, :settlement_updated)
    end
  end
end
