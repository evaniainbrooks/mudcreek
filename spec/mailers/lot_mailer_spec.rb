require "rails_helper"

RSpec.describe LotMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:owner)      { create(:user, first_name: "Alice", last_name: "Smith") }
  let(:lot)        { create(:lot, owner: owner) }
  let(:settlement) { Settlement.create!(lot: lot) }

  describe "#payout_sent" do
    before do
      settlement.settlement_line_items.create!(
        description: "Hammer price",
        line_item_type: :hammer_price,
        amount_cents: 50_000
      )
    end

    subject(:mail) { LotMailer.payout_sent(lot) }

    it "sends to the lot owner" do
      expect(mail.to).to eq([owner.email_address])
    end

    it "includes the lot name in the subject" do
      expect(mail.subject).to include(lot.name)
    end

    it "addresses the owner by first name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Alice")
    end

    it "includes the lot name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(lot.name)
    end

    it "includes the payout amount in the HTML body" do
      expect(mail.html_part.body.to_s).to include("500")
    end

    it "includes the payout amount in the text body" do
      expect(mail.text_part.body.to_s).to include("500")
    end

    it "addresses the owner by first name in the text body" do
      expect(mail.text_part.body.to_s).to include("Alice")
    end
  end

  describe "#settlement_updated" do
    before do
      settlement.settlement_line_items.create!(
        description: "Hammer price",
        line_item_type: :hammer_price,
        amount_cents: 100_000
      )
      settlement.settlement_line_items.create!(
        description: "Seller commission",
        line_item_type: :seller_commission,
        amount_cents: 15_000
      )
    end

    subject(:mail) { LotMailer.settlement_updated(settlement) }

    it "sends to the lot owner" do
      expect(mail.to).to eq([owner.email_address])
    end

    it "includes the lot name in the subject" do
      expect(mail.subject).to include(lot.name)
    end

    it "addresses the owner by first name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Alice")
    end

    it "includes the lot name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(lot.name)
    end

    it "lists each line item description in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Hammer price")
      expect(mail.html_part.body.to_s).to include("Seller commission")
    end

    it "shows the net payout in the HTML body" do
      # 100_000 - 15_000 = 85_000 cents = $850
      expect(mail.html_part.body.to_s).to include("850")
    end

    it "shows the net payout in the text body" do
      expect(mail.text_part.body.to_s).to include("850")
    end
  end
end
