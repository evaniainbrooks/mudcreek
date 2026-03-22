require "rails_helper"

RSpec.describe "Profiles", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true, features: { auctions: true })
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "PATCH /profile" do
    context "with valid name params" do
      it "updates the user's name and redirects" do
        patch profile_path, params: { user: { first_name: "Jane", last_name: "Doe" } }
        expect(response).to redirect_to(edit_profile_path)
        expect(user.reload.first_name).to eq("Jane")
        expect(user.reload.last_name).to eq("Doe")
      end

      it "sets a success notice" do
        patch profile_path, params: { user: { first_name: "Jane", last_name: "Doe" } }
        follow_redirect!
        expect(response.body).to include("Profile updated successfully.")
      end
    end

    context "with address params (no existing address)" do
      it "creates the address and redirects" do
        patch profile_path, params: {
          user: {
            first_name: user.first_name,
            last_name: user.last_name,
            address_attributes: {
              street_address: "123 Main St",
              city: "Halifax",
              province: "NS",
              postal_code: "B3H 1A1",
              country: "CA"
            }
          }
        }
        expect(response).to redirect_to(edit_profile_path)
        expect(user.reload.address.city).to eq("Halifax")
      end
    end

    context "with address params (existing address)" do
      before do
        patch profile_path, params: {
          user: {
            first_name: user.first_name,
            last_name: user.last_name,
            address_attributes: { street_address: "1 Old St", city: "Truro", province: "NS",
                                  postal_code: "B2N 1A1", country: "CA" }
          }
        }
      end

      it "updates the existing address" do
        patch profile_path, params: {
          user: {
            first_name: user.first_name,
            last_name: user.last_name,
            address_attributes: { street_address: "99 New Ave", city: "Dartmouth", province: "NS",
                                  postal_code: "B2Y 1A1", country: "CA" }
          }
        }
        expect(response).to redirect_to(edit_profile_path)
        expect(user.reload.address.city).to eq("Dartmouth")
        expect(user.address.street_address).to eq("99 New Ave")
      end
    end

    context "with invalid params" do
      it "renders the edit form with unprocessable_content status" do
        patch profile_path, params: { user: { first_name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch profile_path, params: { user: { first_name: "Jane", last_name: "Doe" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /profile/edit — profile tab" do
    it "pre-fills the user's name" do
      get edit_profile_path

      expect(response.body).to include(user.first_name)
      expect(response.body).to include(user.last_name)
    end

    context "when the user has no address" do
      it "renders the form without error" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user already has an address" do
      before do
        patch profile_path, params: {
          user: {
            first_name: user.first_name,
            last_name: user.last_name,
            address_attributes: { street_address: "1 Main St", city: "Halifax",
                                  province: "NS", postal_code: "B3H 1A1", country: "CA" }
          }
        }
      end

      it "pre-fills address fields" do
        get edit_profile_path

        expect(response.body).to include("1 Main St")
        expect(response.body).to include("Halifax")
      end
    end
  end

  describe "GET /profile/invoices" do
    context "when the user has no invoices" do
      it "returns 200" do
        get profile_invoices_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the empty state message" do
        get profile_invoices_path

        expect(response.body).to include("You have no invoices yet.")
      end
    end

    context "when the user has invoices" do
      let!(:invoice) { create(:invoice, user: user) }

      it "displays the invoice number" do
        get profile_invoices_path

        expect(response.body).to include(invoice.number)
      end

      it "shows an Unpaid badge for unpaid invoices" do
        get profile_invoices_path

        expect(response.body).to include("Unpaid")
      end
    end

    context "when the user has a paid invoice" do
      let!(:invoice) { create(:invoice, :paid, user: user) }

      it "shows a Paid badge" do
        get profile_invoices_path

        expect(response.body).to include("Paid")
      end
    end

    context "when another user has invoices" do
      let(:other_user) { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_user) }

      it "does not display the other user's invoice" do
        get profile_invoices_path

        expect(response.body).not_to include(other_invoice.number)
      end
    end
  end

  describe "GET /profile/orders" do
    context "when the user has no orders" do
      it "returns 200" do
        get profile_orders_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the empty state message" do
        get profile_orders_path

        expect(response.body).to include("You haven&#39;t placed any orders yet.")
      end
    end

    context "when the user has orders" do
      let!(:order) { create(:order, user: user) }

      it "returns 200" do
        get profile_orders_path

        expect(response).to have_http_status(:ok)
      end

      it "displays the order number" do
        get profile_orders_path

        expect(response.body).to include(order.number)
      end

      it "displays the order total" do
        get profile_orders_path

        expect(response.body).to include("11.50")
      end
    end

    context "when the user has multiple orders" do
      let!(:older_order) { create(:order, user: user, created_at: 2.days.ago) }
      let!(:newer_order) { create(:order, user: user, created_at: 1.day.ago) }

      it "shows the newer order before the older one" do
        get profile_orders_path

        expect(response.body.index(newer_order.number)).to be < response.body.index(older_order.number)
      end
    end

    context "when another user has orders" do
      let(:other_user) { create(:user) }
      let!(:other_order) { create(:order, user: other_user) }

      it "does not display the other user's order" do
        get edit_profile_path

        expect(response.body).not_to include(other_order.number)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get edit_profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /profile/auctions" do
    let(:auction) { create(:auction, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
    let!(:auction_listing) { create(:auction_listing, auction: auction, starting_bid_cents: 1000) }

    before do
      schedule = BidIncrementSchedule.create!(auction_id: nil)
      schedule.tiers.create!(min_amount_cents: 0, increment_cents: 500)
      registration = AuctionRegistration.create!(auction: auction, user: user, state: :approved)
      auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :placed)
    end

    it "returns Turbo Stream with bid registrations" do
      get profile_auctions_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(auction.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get profile_auctions_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /profile/listings" do
    let(:listing) { create(:listing) }

    before do
      order = create(:order, user: user, status: :paid)
      order.order_items.create!(listing: listing, name: listing.name, price_cents: listing.price_cents)
    end

    it "returns Turbo Stream with purchased listings" do
      get profile_listings_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(listing.name)
    end

    it "does not include listings from unpaid orders" do
      other_listing = create(:listing)
      pending_order = create(:order, user: user, status: :pending)
      pending_order.order_items.create!(listing: other_listing, name: other_listing.name, price_cents: other_listing.price_cents)

      get profile_listings_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).not_to include(other_listing.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get profile_listings_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /profile/auctions/:hashid" do
    let(:auction) { create(:auction, starts_at: 1.day.ago, ends_at: 1.day.from_now) }
    let(:listing) { create(:listing) }
    let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
    let!(:registration) { AuctionRegistration.create!(auction: auction, user: user, state: :approved) }

    before do
      schedule = BidIncrementSchedule.create!(auction_id: nil)
      schedule.tiers.create!(min_amount_cents: 0, increment_cents: 500)
      auction_listing.bids.create!(auction_registration: registration, amount_cents: 1000, state: :placed)
    end

    it "returns 200 and shows bids for the user's registration" do
      get auction_bids_profile_path(hashid: auction.hashid)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(listing.name)
    end

    context "when the user has no registration for the auction" do
      let(:other_auction) { create(:auction) }

      it "returns 404" do
        get auction_bids_profile_path(hashid: other_auction.hashid)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get auction_bids_profile_path(hashid: auction.hashid)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
