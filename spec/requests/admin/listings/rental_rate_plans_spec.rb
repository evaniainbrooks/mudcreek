require "rails_helper"

RSpec.describe "Admin::Listings::RentalRatePlans", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "rate_plan_manager", description: "Manage rate plans").tap do |r|
      r.permissions.create!(resource: "Listings::RentalRatePlan", action: "create")
      r.permissions.create!(resource: "Listings::RentalRatePlan", action: "destroy")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:listing) { create(:listing, listing_type: :rental) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/:listing_hashid/rental_rate_plans" do
    let(:valid_params) do
      { listings_rental_rate_plan: { label: "1 Hour", duration_minutes: 60, price: "15.00" } }
    end

    context "with valid params" do
      it "creates a rate plan" do
        expect {
          post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: valid_params
        }.to change { listing.rental_rate_plans.count }.by(1)
      end

      it "redirects to the listing edit page" do
        post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(edit_admin_listing_path(listing))
      end

      it "responds with turbo stream when requested" do
        post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid),
             params: valid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("rental-rate-plans")
        expect(response.body).to include("rental-rate-plan-form")
      end
    end

    context "with invalid params (missing label)" do
      let(:invalid_params) do
        { listings_rental_rate_plan: { label: "", duration_minutes: 60, price: "15.00" } }
      end

      it "does not create a rate plan" do
        expect {
          post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: invalid_params
        }.not_to change { listing.rental_rate_plans.count }
      end

      it "redirects to the listing edit page" do
        post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: invalid_params

        expect(response).to redirect_to(edit_admin_listing_path(listing))
      end

      it "re-renders the form via turbo stream" do
        post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid),
             params: invalid_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("rental-rate-plan-form")
      end
    end

    context "when the listing does not exist" do
      it "returns 404" do
        post admin_listing_rental_rate_plans_path(listing_hashid: "doesnotexist"), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_rate_plans", description: "No rate plan access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listing_rental_rate_plans_path(listing_hashid: listing.hashid), params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/listings/:listing_hashid/rental_rate_plans/:id" do
    let!(:rate_plan) { create(:listings_rental_rate_plan, listing: listing) }

    it "destroys the rate plan" do
      expect {
        delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: rate_plan.id)
      }.to change { listing.rental_rate_plans.count }.by(-1)
    end

    it "redirects to the listing edit page" do
      delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: rate_plan.id)

      expect(response).to redirect_to(edit_admin_listing_path(listing))
    end

    it "responds with a turbo stream remove action when requested" do
      delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: rate_plan.id),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(rate_plan))
    end

    context "when the rate plan belongs to a different listing" do
      let(:other_listing) { create(:listing, listing_type: :rental) }
      let!(:other_rate_plan) { create(:listings_rental_rate_plan, listing: other_listing) }

      it "returns 404" do
        delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: other_rate_plan.id)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: rate_plan.id)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) { Role.create!(name: "no_rate_plans", description: "No rate plan access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listing_rental_rate_plan_path(listing_hashid: listing.hashid, id: rate_plan.id)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
