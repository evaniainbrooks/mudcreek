require "rails_helper"

RSpec.describe "Listings", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:browser_ua) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36" }

  describe "GET /listings/:hashid" do
    let!(:listing_a) { create(:listing, name: "Listing A", published: true) }
    let!(:listing_b) { create(:listing, name: "Listing B", published: true) }
    let!(:listing_c) { create(:listing, name: "Listing C", published: true) }

    def visit(listing)
      get listing_path(listing), headers: { "HTTP_USER_AGENT" => browser_ua }
    end

    it "records the listing in the session" do
      visit(listing_a)

      expect(session[:recently_viewed]).to include(a_hash_including("hashid" => listing_a.hashid))
    end

    it "records a viewed_at timestamp in the session entry" do
      freeze_time do
        visit(listing_a)

        entry = session[:recently_viewed].find { |e| e["hashid"] == listing_a.hashid }
        expect(entry["viewed_at"]).to eq(Time.current.utc.iso8601(3))
      end
    end

    it "updates viewed_at when a listing is revisited" do
      visit(listing_a)

      travel 1.minute do
        visit(listing_a)

        entry = session[:recently_viewed].find { |e| e["hashid"] == listing_a.hashid }
        expect(entry["viewed_at"]).to eq(Time.current.utc.iso8601(3))
      end
    end

    it "bumps a previously viewed listing to the front when revisited" do
      visit(listing_a)
      visit(listing_b)
      visit(listing_c)

      expect(session[:recently_viewed].first["hashid"]).to eq(listing_c.hashid)

      visit(listing_a)

      expect(session[:recently_viewed].first["hashid"]).to eq(listing_a.hashid)
    end

    it "does not duplicate entries when the same listing is revisited" do
      visit(listing_a)
      visit(listing_b)
      visit(listing_a)

      hashids = session[:recently_viewed].map { |e| e["hashid"] }
      expect(hashids.count(listing_a.hashid)).to eq(1)
    end

    it "shows the most recently viewed listing first (excluding the current page)" do
      visit(listing_a)
      visit(listing_b)
      visit(listing_c)

      # On listing C's page, B should appear first (viewed more recently than A)
      expect(response.body).to include(listing_b.name)

      body_b_pos = response.body.index(listing_b.name)
      body_a_pos = response.body.index(listing_a.name)
      expect(body_b_pos).to be < body_a_pos
    end
  end
end
