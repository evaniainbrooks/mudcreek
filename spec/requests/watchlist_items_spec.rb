require "rails_helper"

RSpec.describe "WatchlistItems", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true, features: { watchlist: true })
  end

  let(:user) { create(:user) }
  let!(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /watchlist_items" do
    it "adds the listing to the user's watchlist" do
      expect {
        post watchlist_items_path, params: { listing_id: listing.id }
      }.to change { user.watchlist_items.count }.by(1)
    end

    it "creates a watchlist item for the correct listing" do
      post watchlist_items_path, params: { listing_id: listing.id }

      expect(user.watchlist_items.last.listing).to eq(listing)
    end

    it "redirects back" do
      post watchlist_items_path, params: { listing_id: listing.id }

      expect(response).to have_http_status(:redirect)
    end

    context "when the listing is already watched" do
      before { user.watchlist_items.create!(listing: listing) }

      it "does not add a duplicate watchlist item" do
        expect {
          post watchlist_items_path, params: { listing_id: listing.id }
        }.not_to change { user.watchlist_items.count }
      end
    end

    context "when the listing belongs to another tenant" do
      let(:other_tenant) { Tenant.create!(name: "Other", key: "other") }
      let!(:other_listing) { create(:listing, tenant: other_tenant) }

      it "returns 404" do
        post watchlist_items_path, params: { listing_id: other_listing.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post watchlist_items_path, params: { listing_id: listing.id }

        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a watchlist item" do
        expect {
          post watchlist_items_path, params: { listing_id: listing.id }
        }.not_to change { WatchlistItem.count }
      end
    end
  end

  describe "DELETE /watchlist_items/:id" do
    let!(:watchlist_item) { user.watchlist_items.create!(listing: listing) }

    it "removes the watchlist item" do
      expect {
        delete watchlist_item_path(watchlist_item)
      }.to change { user.watchlist_items.count }.by(-1)
    end

    it "redirects back" do
      delete watchlist_item_path(watchlist_item)

      expect(response).to have_http_status(:redirect)
    end

    context "when the watchlist item belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_listing) { create(:listing) }
      let!(:other_item) { other_user.watchlist_items.create!(listing: other_listing) }

      it "returns 404" do
        delete watchlist_item_path(other_item)

        expect(response).to have_http_status(:not_found)
      end

      it "does not destroy the other user's watchlist item" do
        delete watchlist_item_path(other_item)

        expect(WatchlistItem.find_by(id: other_item.id)).to be_present
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete watchlist_item_path(watchlist_item)

        expect(response).to redirect_to(new_session_path)
      end

      it "does not destroy the watchlist item" do
        expect {
          delete watchlist_item_path(watchlist_item)
        }.not_to change { WatchlistItem.count }
      end
    end
  end
end
