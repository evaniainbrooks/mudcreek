require "rails_helper"

RSpec.describe "Auctions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let!(:auction) { create(:auction, published: true, name: "Spring Auction") }

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
  end
end
