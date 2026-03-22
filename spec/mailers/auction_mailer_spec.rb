require "rails_helper"

RSpec.describe AuctionMailer, type: :mailer do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction)      { create(:auction, admin_email_address: "auction-admin@example.com") }
  let(:registrant)   { create(:user) }
  let(:registration) { AuctionRegistration.create!(auction: auction, user: registrant) }

  describe "#registration_pending" do
    subject(:mail) { AuctionMailer.registration_pending(registration) }

    it "sends to the auction admin email address" do
      expect(mail.to).to eq(["auction-admin@example.com"])
    end

    it "includes the auction name in the subject" do
      expect(mail.subject).to include(auction.name)
    end

    it "includes the registrant name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(registrant.name)
    end

    it "includes the registrant email in the HTML body" do
      expect(mail.html_part.body.to_s).to include(registrant.email_address)
    end

    it "includes a link to the admin auction page in the HTML body" do
      expect(mail.html_part.body.to_s).to include(auction.hashid)
    end

    it "includes the registrant name in the text body" do
      expect(mail.text_part.body.to_s).to include(registrant.name)
    end
  end

  describe "#registration_approved" do
    subject(:mail) { AuctionMailer.registration_approved(registration) }

    it "sends to the registrant" do
      expect(mail.to).to eq([registrant.email_address])
    end

    it "includes the auction name in the subject" do
      expect(mail.subject).to include(auction.name)
    end

    it "includes the registrant name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(registrant.name)
    end

    it "includes the auction name in the HTML body" do
      expect(mail.html_part.body.to_s).to include(auction.name)
    end

    it "includes a link to the auction in the HTML body" do
      expect(mail.html_part.body.to_s).to include(auction.hashid)
    end

    it "includes the registrant name in the text body" do
      expect(mail.text_part.body.to_s).to include(registrant.name)
    end
  end
end
