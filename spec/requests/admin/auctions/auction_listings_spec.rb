require "rails_helper"

RSpec.describe "Admin::Auctions::AuctionListings", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "auction_manager", description: "Manage auctions").tap do |r|
      r.permissions.create!(resource: "Auction",        action: "show")
      r.permissions.create!(resource: "AuctionListing", action: "update")
      r.permissions.create!(resource: "AuctionListing", action: "destroy")
      r.permissions.create!(resource: "AuctionListing", action: "reorder")
    end
  end

  let(:user)             { create(:user, role: role) }
  let!(:auction)         { create(:auction) }
  let!(:listing)         { create(:listing) }
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/auctions/:auction_hashid/auction_listings/:id" do
    it "removes the auction listing and redirects to the auction" do
      expect {
        delete admin_auction_auction_listing_path(auction, auction_listing)
      }.to change(AuctionListing, :count).by(-1)

      expect(response).to redirect_to(admin_auction_path(auction))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_auction_auction_listing_path(auction, auction_listing)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks destroy permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_auction_auction_listing_path(auction, auction_listing)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/auctions/:auction_hashid/auction_listings/:id" do
    it "updates bid details and redirects" do
      patch admin_auction_auction_listing_path(auction, auction_listing),
        params: { auction_listing: { starting_bid: "500" } }

      expect(auction_listing.reload.starting_bid_cents).to eq(500_00)
      expect(response).to redirect_to(admin_auction_path(auction))
    end

    it "responds with turbo stream when requested" do
      patch admin_auction_auction_listing_path(auction, auction_listing),
        params: { auction_listing: { starting_bid: "100" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/auctions/:auction_hashid/auction_listings/reorder" do
    it "returns 200" do
      patch reorder_admin_auction_auction_listings_path(auction),
        params: { id: auction_listing.id, position: 1 }

      expect(response).to have_http_status(:ok)
    end
  end
end
