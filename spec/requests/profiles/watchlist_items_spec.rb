require "rails_helper"

RSpec.describe "Profiles::WatchlistItems", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)     { create(:user) }
  let!(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /profile/watchlist" do
    it "returns 200" do
      get profile_watchlist_path

      expect(response).to have_http_status(:ok)
    end

    context "with watchlisted listings" do
      before { user.watchlist_items.create!(listing: listing) }

      it "displays the listing name" do
        get profile_watchlist_path

        expect(response.body).to include(listing.name)
      end
    end

    context "when filtering by search" do
      before { user.watchlist_items.create!(listing: listing) }

      it "returns matching listings" do
        get profile_watchlist_path, params: { search: listing.name }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(listing.name)
      end

      it "returns 200 with no matches" do
        get profile_watchlist_path, params: { search: "zzznomatch" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when filtering by category" do
      let!(:category) { create(:listings_category) }

      before do
        listing.categories << category
        user.watchlist_items.create!(listing: listing)
      end

      it "returns listings in the category" do
        get profile_watchlist_path, params: { category_id: category.hashid }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(listing.name)
      end

      it "excludes listings not in the category" do
        other_listing = create(:listing)
        user.watchlist_items.create!(listing: other_listing)

        get profile_watchlist_path, params: { category_id: category.hashid }

        main_content = Nokogiri::HTML(response.body).at_css("main").text
        expect(main_content).not_to include(other_listing.name)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get profile_watchlist_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
