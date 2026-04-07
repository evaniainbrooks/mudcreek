require "rails_helper"

RSpec.describe "Admin::Listings::Copies", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "listing_manager", description: "Manage listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "update")
    end
  end

  let(:user)     { create(:user, role: role) }
  let!(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/:listing_hashid/copies" do
    subject(:make_request) { post admin_listing_copies_path(listing_hashid: listing.hashid) }

    it "creates a new listing" do
      expect { make_request }.to change(Listing, :count).by(1)
    end

    it "sets the copy name to 'Copy of <original>'" do
      make_request
      expect(Listing.last.name).to eq("Copy of #{listing.name}")
    end

    it "creates the copy as unpublished" do
      make_request
      expect(Listing.last.published).to be(false)
    end

    it "redirects to the edit page for the new listing" do
      make_request
      expect(response).to redirect_to(edit_admin_listing_path(Listing.last))
    end

    it "sets a success notice" do
      make_request
      expect(flash[:notice]).to be_present
    end

    context "when the listing has categories" do
      let(:category) { create(:listings_category) }
      let(:listing)  { create(:listing, categories: [category]) }

      it "copies the categories onto the new listing" do
        make_request
        expect(Listing.last.categories).to eq([category])
      end
    end

    context "when the listing has properties" do
      let(:listing) { create(:listing) }

      before { listing.properties.create!(name: "Material", value: "Wood", position: 1) }

      it "copies the properties onto the new listing" do
        make_request
        copy = Listing.last
        expect(copy.properties.count).to eq(1)
        expect(copy.properties.first).to have_attributes(name: "Material", value: "Wood")
      end

      it "does not share property records with the original" do
        make_request
        expect(Listing.last.properties.first.id).not_to eq(listing.properties.first.id)
      end
    end

    context "when the listing has rental rate plans" do
      let(:listing) { create(:listing) }

      before { create(:listings_rental_rate_plan, listing: listing, label: "Hourly", duration_minutes: 60, price_cents: 2000) }

      it "copies the rate plans onto the new listing" do
        make_request
        copy = Listing.last
        expect(copy.rental_rate_plans.count).to eq(1)
        expect(copy.rental_rate_plans.first).to have_attributes(label: "Hourly", duration_minutes: 60, price_cents: 2000)
      end

      it "does not share rate plan records with the original" do
        make_request
        expect(Listing.last.rental_rate_plans.first.id).not_to eq(listing.rental_rate_plans.first.id)
      end
    end

    context "when the listing does not exist" do
      it "returns 404" do
        post admin_listing_copies_path(listing_hashid: "doesnotexist")
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect { make_request }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
