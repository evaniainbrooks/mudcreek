require "rails_helper"

RSpec.describe "Auctions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let!(:auction) { create(:auction, published: true, name: "Spring Auction") }

  # ------------------------------------------------------------------ #
  describe "GET /auctions" do
    it "returns 200" do
      get auctions_path

      expect(response).to have_http_status(:ok)
    end

    it "is accessible without signing in" do
      get auctions_path

      expect(response).to have_http_status(:ok)
    end

    it "displays published auctions" do
      get auctions_path

      expect(response.body).to include("Spring Auction")
    end

    it "does not display unpublished auctions" do
      create(:auction, published: false, name: "Hidden Auction")

      get auctions_path

      expect(response.body).not_to include("Hidden Auction")
    end

    context "search" do
      before { create(:auction, published: true, name: "Winter Sale") }

      it "returns matching auctions" do
        get auctions_path, params: { search: "Spring" }

        expect(response.body).to include("Spring Auction")
        expect(response.body).not_to include("Winter Sale")
      end

      it "is case-insensitive" do
        get auctions_path, params: { search: "spring" }

        expect(response.body).to include("Spring Auction")
      end

      it "returns all auctions when search is blank" do
        get auctions_path, params: { search: "" }

        expect(response.body).to include("Spring Auction")
        expect(response.body).to include("Winter Sale")
      end
    end

    context "state filtering" do
      let!(:live_auction)     { create(:auction, published: true, name: "Live Now",   starts_at: 1.hour.ago,   ends_at: 1.hour.from_now) }
      let!(:upcoming_auction) { create(:auction, published: true, name: "Coming Soon", starts_at: 1.hour.from_now, ends_at: 2.hours.from_now) }
      let!(:ended_auction)    { create(:auction, published: true, name: "All Done",   starts_at: 2.hours.ago,  ends_at: 1.hour.ago) }

      it "filters to live auctions" do
        get auctions_path, params: { state: "live" }

        expect(response.body).to include("Live Now")
        expect(response.body).not_to include("Coming Soon")
        expect(response.body).not_to include("All Done")
      end

      it "filters to upcoming auctions" do
        get auctions_path, params: { state: "upcoming" }

        expect(response.body).to include("Coming Soon")
        expect(response.body).not_to include("Live Now")
        expect(response.body).not_to include("All Done")
      end

      it "filters to ended auctions" do
        get auctions_path, params: { state: "ended" }

        expect(response.body).to include("All Done")
        expect(response.body).not_to include("Live Now")
        expect(response.body).not_to include("Coming Soon")
      end

      it "ignores an invalid state and returns all auctions" do
        get auctions_path, params: { state: "bogus" }

        expect(response.body).to include("Live Now")
        expect(response.body).to include("Coming Soon")
        expect(response.body).to include("All Done")
      end
    end

    context "ordering" do
      let!(:live_auction)     { create(:auction, published: true, name: "Live Now",    starts_at: 1.hour.ago,    ends_at: 1.hour.from_now) }
      let!(:upcoming_auction) { create(:auction, published: true, name: "Coming Soon", starts_at: 1.hour.from_now, ends_at: 2.hours.from_now) }
      let!(:ended_auction)    { create(:auction, published: true, name: "All Done",    starts_at: 2.hours.ago,   ends_at: 1.hour.ago) }

      it "shows live before upcoming before ended" do
        get auctions_path

        body = response.body
        expect(body.index("Live Now")).to be < body.index("Coming Soon")
        expect(body.index("Coming Soon")).to be < body.index("All Done")
      end
    end

    context "category filtering" do
      let!(:category) { create(:listings_category) }
      let!(:listing)  { create(:listing) }

      before do
        listing.categories << category
        create(:auction_listing, auction: auction, listing: listing)
      end

      it "returns auctions that have listings in the category" do
        get auctions_path, params: { category_id: category.hashid }

        expect(response.body).to include("Spring Auction")
      end

      it "excludes auctions with no listings in the category" do
        other_auction = create(:auction, published: true, name: "Other Auction")

        get auctions_path, params: { category_id: category.hashid }

        expect(response.body).not_to include("Other Auction")
      end

      it "returns all auctions when category_id is unknown" do
        get auctions_path, params: { category_id: "nonexistent" }

        expect(response.body).to include("Spring Auction")
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { post session_path, params: { email_address: user.email_address, password: "password" } }

      it "returns 200" do
        get auctions_path

        expect(response).to have_http_status(:ok)
      end

      it "loads registration state for the current user" do
        AuctionRegistration.create!(auction: auction, user: user)

        get auctions_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /auctions/:hashid" do
    it "returns 200 for a published auction" do
      get auction_path(auction)

      expect(response).to have_http_status(:ok)
    end

    it "displays the auction name" do
      get auction_path(auction)

      expect(response.body).to include("Spring Auction")
    end

    it "is accessible without signing in" do
      get auction_path(auction)

      expect(response).to have_http_status(:ok)
    end

    context "when the auction is unpublished" do
      let!(:auction) { create(:auction, published: false) }

      it "returns 404" do
        get auction_path(auction)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "auction listings" do
      let!(:listing)         { create(:listing, name: "Red Chair", state: :on_sale) }
      let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }

      it "displays listings belonging to the auction" do
        get auction_path(auction)

        expect(response.body).to include("Red Chair")
      end

      it "returns 200 with auction listings present" do
        get auction_path(auction)

        expect(response).to have_http_status(:ok)
      end

      context "state filter" do
        let!(:sold_listing) { create(:listing, name: "Blue Table", state: :sold) }
        let!(:sold_al)      { create(:auction_listing, auction: auction, listing: sold_listing) }

        it "filters to on_sale listings" do
          get auction_path(auction), params: { state: "on_sale" }

          expect(response.body).to include("Red Chair")
          expect(response.body).not_to include("Blue Table")
        end

        it "filters to sold listings" do
          get auction_path(auction), params: { state: "sold" }

          expect(response.body).to include("Blue Table")
          expect(response.body).not_to include("Red Chair")
        end
      end

      context "search filter" do
        let!(:other_listing) { create(:listing, name: "Blue Table", state: :on_sale) }
        let!(:other_al)      { create(:auction_listing, auction: auction, listing: other_listing) }

        it "returns listings matching the search term" do
          get auction_path(auction), params: { search: "Chair" }

          expect(response.body).to include("Red Chair")
          expect(response.body).not_to include("Blue Table")
        end

        it "is case-insensitive" do
          get auction_path(auction), params: { search: "red chair" }

          expect(response.body).to include("Red Chair")
        end
      end

      context "category filter" do
        let!(:category)      { create(:listings_category) }
        let!(:other_listing) { create(:listing, name: "Blue Table", state: :on_sale) }
        let!(:other_al)      { create(:auction_listing, auction: auction, listing: other_listing) }

        before { listing.categories << category }

        it "returns listings in the category" do
          get auction_path(auction), params: { category_id: category.hashid }

          expect(response.body).to include("Red Chair")
          expect(response.body).not_to include("Blue Table")
        end
      end
    end

    context "when signed in with an existing registration" do
      let(:user) { create(:user) }

      before do
        post session_path, params: { email_address: user.email_address, password: "password" }
        AuctionRegistration.create!(auction: auction, user: user)
      end

      it "returns 200" do
        get auction_path(auction)

        expect(response).to have_http_status(:ok)
      end
    end

    context "my_bids filter" do
      let(:user)    { create(:user) }
      let(:listing) { create(:listing, name: "Bid Listing") }
      let(:other_listing) { create(:listing, name: "Other Listing") }
      let!(:schedule) do
        s = BidIncrementSchedule.create!(auction_id: nil)
        s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
        s
      end
      let(:auction) { create(:auction, published: true, name: "Spring Auction", starts_at: 1.day.ago, ends_at: 1.day.from_now) }
      let!(:auction_listing)       { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
      let!(:other_auction_listing) { create(:auction_listing, auction: auction, listing: other_listing, starting_bid_cents: 1000) }

      before do
        post session_path, params: { email_address: user.email_address, password: "password" }
        registration = AuctionRegistration.create!(auction: auction, user: user, state: :approved)
        auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :placed)
      end

      it "shows only listings the user has bid on" do
        get auction_path(auction), params: { filter: "my_bids" }

        expect(response.body).to include("Bid Listing")
        expect(response.body).not_to include("Other Listing")
      end
    end

    context "my_listings filter" do
      let(:user)    { create(:user) }
      let(:listing) { create(:listing, name: "Won Listing", state: :on_sale) }
      let(:other_listing) { create(:listing, name: "Not Won", state: :on_sale) }
      let!(:schedule) do
        s = BidIncrementSchedule.create!(auction_id: nil)
        s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
        s
      end
      # Start live so bids can be placed, then move to ended before the assertion
      let(:auction) { create(:auction, published: true, name: "Spring Auction", starts_at: 2.days.ago, ends_at: 1.day.from_now) }
      let!(:auction_listing)       { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000, ends_at: 1.day.from_now) }
      let!(:other_auction_listing) { create(:auction_listing, auction: auction, listing: other_listing, starting_bid_cents: 1000, ends_at: 1.day.from_now) }

      before do
        post session_path, params: { email_address: user.email_address, password: "password" }
        registration = AuctionRegistration.create!(auction: auction, user: user, state: :approved)
        auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :placed)
        # Mark the won listing as sold and close the auction
        listing.update_columns(state: "sold")
        auction.update_columns(ends_at: 1.day.ago)
        auction_listing.update_columns(ends_at: 1.day.ago)
        other_auction_listing.update_columns(ends_at: 1.day.ago)
      end

      it "shows only listings where the user is the top bidder" do
        get auction_path(auction), params: { filter: "my_listings" }

        expect(response.body).to include("Won Listing")
        expect(response.body).not_to include("Not Won")
      end
    end

    context "my_bids and my_listings filters when unauthenticated" do
      it "ignores the filter param for my_bids" do
        get auction_path(auction), params: { filter: "my_bids" }

        expect(response).to have_http_status(:ok)
      end

      it "ignores the filter param for my_listings" do
        get auction_path(auction), params: { filter: "my_listings" }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
