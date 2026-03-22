require "rails_helper"

RSpec.describe InvoiceMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user)    { create(:user, first_name: "Sam", last_name: "Lee") }
  let(:auction) { create(:auction) }
  let(:invoice) { create(:invoice, user: user, auction: auction, total_cents: 10_050) }

  before do
    listing_one = create(:listing, state: :sold)
    listing_two = create(:listing, state: :sold)
    create(:invoice_item, invoice: invoice, listing: listing_one, name: "Vintage Chair", amount_cents: 5_025)
    create(:invoice_item, invoice: invoice, listing: listing_two, name: "Oak Table", amount_cents: 5_025)
  end

  describe "#invoice_generated" do
    subject(:mail) { InvoiceMailer.invoice_generated(invoice) }

    it "sends to the invoice user" do
      expect(mail.to).to eq([user.email_address])
    end

    it "includes the auction name in the subject" do
      expect(mail.subject).to include(auction.name)
    end

    it "addresses the user by first name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Sam")
    end

    it "includes the auction name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(auction.name)
    end

    it "lists each invoice item name in the HTML body" do
      expect(mail.html_part.body.to_s).to include("Vintage Chair")
      expect(mail.html_part.body.to_s).to include("Oak Table")
    end

    it "includes the invoice total in the HTML body" do
      expect(mail.html_part.body.to_s).to include("100.50")
    end

    it "includes a link to the invoice in the HTML body" do
      expect(mail.html_part.body.to_s).to include(invoice.number)
    end

    it "addresses the user by first name in the text body" do
      expect(mail.text_part.body.to_s).to include("Sam")
    end

    it "lists each invoice item name in the text body" do
      expect(mail.text_part.body.to_s).to include("Vintage Chair")
      expect(mail.text_part.body.to_s).to include("Oak Table")
    end

    it "includes the invoice total in the text body" do
      expect(mail.text_part.body.to_s).to include("100.50")
    end

    it "includes a link to the invoice in the text body" do
      expect(mail.text_part.body.to_s).to include(invoice.number)
    end
  end
end
