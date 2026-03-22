require "rails_helper"

RSpec.describe Admin::AuctionsHelper, type: :helper do
  let(:tenant) { create(:tenant) }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#auction_registration_state_badge" do
    it "returns a warning badge for pending" do
      reg = double(state: "pending")
      html = helper.auction_registration_state_badge(reg)
      expect(html).to include("Pending")
      expect(html).to include("text-bg-warning")
    end

    it "returns a success badge for approved" do
      reg = double(state: "approved")
      html = helper.auction_registration_state_badge(reg)
      expect(html).to include("Approved")
      expect(html).to include("text-bg-success")
    end

    it "returns a danger badge for rejected" do
      reg = double(state: "rejected")
      html = helper.auction_registration_state_badge(reg)
      expect(html).to include("Rejected")
      expect(html).to include("text-bg-danger")
    end
  end

  describe "#render_auctions_table" do
    let(:auction) { create(:auction) }

    subject(:html) { Capybara.string(helper.render_auctions_table(auctions: [auction]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Name column header" do
      expect(html).to have_css("th", text: "Name")
    end

    it "renders the Starts At column header" do
      expect(html).to have_css("th", text: "Starts At")
    end

    it "renders the Ends At column header" do
      expect(html).to have_css("th", text: "Ends At")
    end

    it "renders the Published column header" do
      expect(html).to have_css("th", text: "Published")
    end

    it "renders the Reconciled column header" do
      expect(html).to have_css("th", text: "Reconciled")
    end

    it "renders a link to the auction" do
      expect(html).to have_link(auction.name)
    end

    it "shows '—' for extension when bidding_extension is zero" do
      expect(html).to have_css("td", text: "—")
    end

    it "shows the extension seconds when bidding_extension is positive" do
      auction = create(:auction, bidding_extension: 30)
      html = Capybara.string(helper.render_auctions_table(auctions: [auction]).to_s)
      expect(html).to have_css("td", text: "30s")
    end

    it "shows No badge when auction is not published" do
      expect(html).to have_css("span.badge.text-bg-danger", text: "No")
    end

    it "shows Yes badge when auction is published" do
      auction = create(:auction, published: true)
      html = Capybara.string(helper.render_auctions_table(auctions: [auction]).to_s)
      expect(html).to have_css("span.badge.text-bg-success", text: "Yes")
    end

    it "renders a row for each auction" do
      create(:auction)
      auctions = Auction.all.to_a
      html = Capybara.string(helper.render_auctions_table(auctions: auctions).to_s)
      expect(html).to have_css("tbody tr", count: auctions.size)
    end
  end

  describe "#render_auction_registrations_table" do
    let(:auction) { create(:auction) }
    let(:user)    { create(:user) }
    let(:registration) { AuctionRegistration.create!(auction: auction, user: user) }

    subject(:html) { Capybara.string(helper.render_auction_registrations_table(registrations: [registration]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the User column header" do
      expect(html).to have_css("th", text: "User")
    end

    it "renders the State column header" do
      expect(html).to have_css("th", text: "State")
    end

    it "renders the Notes column header" do
      expect(html).to have_css("th", text: "Notes")
    end

    it "renders the Registered column header" do
      expect(html).to have_css("th", text: "Registered")
    end

    it "renders the Updated column header" do
      expect(html).to have_css("th", text: "Updated")
    end

    it "renders a row for each registration" do
      expect(html).to have_css("tbody tr", count: 1)
    end
  end

  describe "#render_auction_report_table" do
    let(:auction)         { create(:auction) }
    let(:listing)         { create(:listing) }
    let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }

    subject(:html) { Capybara.string(helper.render_auction_report_table(report_listings: [auction_listing]).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Listing column header" do
      expect(html).to have_css("th", text: "Listing")
    end

    it "renders the Bids column header" do
      expect(html).to have_css("th", text: "Bids")
    end

    it "renders the Highest Bid column header" do
      expect(html).to have_css("th", text: "Highest Bid")
    end

    it "renders a link to the listing" do
      expect(html).to have_link(listing.name)
    end

    it "renders a footer row with totals" do
      expect(html).to have_css("tfoot td", text: "Total")
    end
  end

  describe "#render_auction_listings_table" do
    let(:auction)         { create(:auction) }
    let(:listing)         { create(:listing) }
    let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }

    subject(:html) do
      Capybara.string(helper.render_auction_listings_table(auction_listings: [auction_listing], auction: auction).to_s)
    end

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders the Name column header" do
      expect(html).to have_css("th", text: "Name")
    end

    it "renders the State column header" do
      expect(html).to have_css("th", text: "State")
    end

    it "renders the Starting Bid column header" do
      expect(html).to have_css("th", text: "Starting Bid")
    end

    it "renders the Reserve column header" do
      expect(html).to have_css("th", text: "Reserve")
    end

    it "renders a link to each listing" do
      expect(html).to have_link(listing.name)
    end

    it "renders a Remove button for each listing" do
      expect(html).to have_button("Remove")
    end

    it "shows '—' for end offset when stagger interval is zero" do
      expect(html).to have_css("td span.text-muted", text: "—")
    end

    it "shows the offset seconds when stagger interval is positive" do
      auction = create(:auction, end_time_stagger_interval: 60)
      listing2 = create(:listing)
      al = create(:auction_listing, auction: auction, listing: listing2, position: 2)
      html = Capybara.string(
        helper.render_auction_listings_table(auction_listings: [al], auction: auction).to_s
      )
      expect(html).to have_css("td span", text: "60s")
    end
  end
end
