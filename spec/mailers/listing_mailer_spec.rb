require "rails_helper"

RSpec.describe ListingMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "#offer_received" do
    let(:listing) { create(:listing) }
    let(:buyer)   { create(:user) }
    let(:offer)   { create(:offer, listing: listing, user: buyer, amount_cents: 7500) }

    subject(:mail) { ListingMailer.offer_received(offer) }

    it "sends to the listing owner" do
      expect(mail.to).to eq([listing.owner.email_address])
    end

    it "includes the listing name in the subject" do
      expect(mail.subject).to include(listing.name)
    end

    it "includes the buyer name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(buyer.name)
    end

    it "includes the buyer email in the HTML body" do
      expect(mail.html_part.body.to_s).to include(buyer.email_address)
    end

    it "includes the offer amount in the HTML body" do
      expect(mail.html_part.body.to_s).to include("75")
    end

    it "includes a link to the listing in the HTML body" do
      expect(mail.html_part.body.to_s).to include(listing.hashid)
    end

    it "includes the buyer name in the text body" do
      expect(mail.text_part.body.to_s).to include(buyer.name)
    end

    context "when the offer includes a message" do
      let(:offer) { create(:offer, listing: listing, user: buyer, amount_cents: 7500, message: "I love this item!") }

      it "includes the message in the HTML body" do
        expect(mail.html_part.body.to_s).to include("I love this item!")
      end

      it "includes the message in the text body" do
        expect(mail.text_part.body.to_s).to include("I love this item!")
      end
    end

    context "when the offer has no message" do
      let(:offer) { create(:offer, listing: listing, user: buyer, amount_cents: 7500, message: nil) }

      it "does not include a message section in the HTML body" do
        expect(mail.html_part.body.to_s).not_to include("Message:")
      end
    end
  end

  describe "#offer_accepted" do
    let(:listing) { create(:listing) }
    let(:buyer)   { create(:user, first_name: "Jane", last_name: "Doe") }
    let(:offer)   { create(:offer, listing: listing, user: buyer, amount_cents: 10_000) }
    let(:invoice) { create(:invoice, user: buyer, offer: offer, total_cents: 10_000) }

    subject(:mail) { ListingMailer.offer_accepted(invoice) }

    it "sends to the buyer" do
      expect(mail.to).to eq([buyer.email_address])
    end

    it "includes the listing name in the subject" do
      expect(mail.subject).to include(listing.name)
    end

    it "addresses the buyer by first name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Jane")
    end

    it "includes the listing name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(listing.name)
    end

    it "includes the invoice total in the HTML body" do
      expect(mail.html_part.body.to_s).to include("100")
    end

    it "includes a link to the invoice in the HTML body" do
      expect(mail.html_part.body.to_s).to include(invoice.number)
    end

    it "includes the invoice total in the text body" do
      expect(mail.text_part.body.to_s).to include("100")
    end
  end
end
