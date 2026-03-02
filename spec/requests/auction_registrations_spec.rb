require "rails_helper"

RSpec.describe "AuctionRegistrations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)    { create(:user) }
  let!(:auction) { create(:auction, published: true) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /auctions/:auction_hashid/auction_registrations" do
    it "creates a registration and redirects to the auction with a notice" do
      post auction_auction_registrations_path(auction)

      expect(response).to redirect_to(auction_path(auction))
      follow_redirect!
      expect(response.body).to include("You're registered!")
    end

    it "creates a pending registration by default" do
      expect { post auction_auction_registrations_path(auction) }
        .to change { AuctionRegistration.count }.by(1)

      expect(AuctionRegistration.last.state).to eq("pending")
    end

    context "when auto_approve is enabled on the auction" do
      let!(:auction) { create(:auction, published: true, auto_approve: true) }

      it "creates an approved registration" do
        post auction_auction_registrations_path(auction)

        expect(AuctionRegistration.last.state).to eq("approved")
      end
    end

    context "when already registered" do
      before { AuctionRegistration.create!(auction: auction, user: user) }

      it "redirects to the auction with an alert" do
        post auction_auction_registrations_path(auction)

        expect(response).to redirect_to(auction_path(auction))
        follow_redirect!
        expect(response.body).to include("You are already registered for this auction.")
      end

      it "does not create a duplicate registration" do
        expect { post auction_auction_registrations_path(auction) }
          .not_to change { AuctionRegistration.count }
      end
    end

    context "when the auction is unpublished" do
      let!(:auction) { create(:auction, published: false) }

      it "returns 404" do
        post auction_auction_registrations_path(auction)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post auction_auction_registrations_path(auction)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
