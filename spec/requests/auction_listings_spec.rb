require "rails_helper"

RSpec.describe "AuctionListings", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:listing) { create(:listing, name: "Vintage Tractor", published: true) }
  let(:auction) { create(:auction, published: true, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing) }

  describe "GET /auctions/:auction_hashid/listings/:hashid" do
    it "returns 200" do
      get auction_auction_listing_path(auction, auction_listing)

      expect(response).to have_http_status(:ok)
    end

    it "displays the listing name" do
      get auction_auction_listing_path(auction, auction_listing)

      expect(response.body).to include("Vintage Tractor")
    end

    it "is accessible without signing in" do
      get auction_auction_listing_path(auction, auction_listing)

      expect(response).to have_http_status(:ok)
    end

    context "when the auction is unpublished" do
      let(:auction) { create(:auction, published: false, starts_at: 1.day.ago, ends_at: 1.day.from_now) }

      it "returns 404" do
        get auction_auction_listing_path(auction, auction_listing)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
