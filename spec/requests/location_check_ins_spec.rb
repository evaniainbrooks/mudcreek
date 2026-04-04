require "rails_helper"

RSpec.describe "LocationCheckIns", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, features: { locations: true })
  end

  let!(:location) { create(:location, name: "Front Desk", published: true) }

  # ------------------------------------------------------------------ #
  describe "GET /locations/:location_id/checkin — authenticated" do
    let(:visitor) { create(:user, first_name: "Alice") }

    before { post session_path, params: { email_address: visitor.email_address, password: "password" } }

    it "returns 200" do
      get location_checkin_path(location)

      expect(response).to have_http_status(:ok)
    end

    it "creates a check-in for the current user" do
      expect {
        get location_checkin_path(location)
      }.to change(CheckIn, :count).by(1)
    end

    it "associates the check-in with the correct user and location" do
      get location_checkin_path(location)

      check_in = CheckIn.last
      expect(check_in.user).to eq(visitor)
      expect(check_in.location).to eq(location)
    end

    it "does not set guest_name" do
      get location_checkin_path(location)

      expect(CheckIn.last.guest_name).to be_nil
    end

    it "shows the success message and the user's name" do
      get location_checkin_path(location)

      expect(response.body).to include("Checked in")
      expect(response.body).to include("Alice")
    end

    it "shows the location name" do
      get location_checkin_path(location)

      expect(response.body).to include("Front Desk")
    end

    it "creates a new check-in on each scan (duplicates allowed)" do
      expect {
        2.times { get location_checkin_path(location) }
      }.to change(CheckIn, :count).by(2)
    end

    it "does not set session[:return_to_after_authenticating]" do
      get location_checkin_path(location)

      expect(session[:return_to_after_authenticating]).to be_nil
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /locations/:location_id/checkin — unauthenticated" do
    it "returns 200" do
      get location_checkin_path(location)

      expect(response).to have_http_status(:ok)
    end

    it "does not create a check-in" do
      expect {
        get location_checkin_path(location)
      }.not_to change(CheckIn, :count)
    end

    it "renders the guest name form" do
      get location_checkin_path(location)

      expect(response.body).to include("Check In")
    end

    it "shows the location name" do
      get location_checkin_path(location)

      expect(response.body).to include("Front Desk")
    end

    it "includes a sign-in link" do
      get location_checkin_path(location)

      expect(response.body).to include(new_session_path)
    end

    it "stores the check-in URL in the session for post-login redirect" do
      get location_checkin_path(location)

      expect(session[:return_to_after_authenticating]).to eq(location_checkin_url(location))
    end

    context "with an unknown location id" do
      it "returns 404" do
        get location_checkin_path(location_hashid: "nonexistent")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /locations/:location_id/checkin — guest check-in" do
    let(:guest_params) { { check_in: { guest_name: "Bob Guest" } } }

    it "redirects to the check-in page" do
      post location_checkin_path(location), params: guest_params

      expect(response).to redirect_to(location_checkin_path(location))
    end

    it "creates a check-in with the guest name" do
      expect {
        post location_checkin_path(location), params: guest_params
      }.to change(CheckIn, :count).by(1)
    end

    it "sets guest_name and leaves user_id nil" do
      post location_checkin_path(location), params: guest_params

      check_in = CheckIn.last
      expect(check_in.guest_name).to eq("Bob Guest")
      expect(check_in.user).to be_nil
    end

    it "shows the success message and guest name after redirect" do
      post location_checkin_path(location), params: guest_params
      follow_redirect!

      expect(response.body).to include("Checked in")
      expect(response.body).to include("Bob Guest")
    end

    it "shows the location name" do
      post location_checkin_path(location), params: guest_params
      follow_redirect!

      expect(response.body).to include("Front Desk")
    end

    context "with a blank guest name" do
      let(:blank_params) { { check_in: { guest_name: "" } } }

      it "does not create a check-in" do
        expect {
          post location_checkin_path(location), params: blank_params
        }.not_to change(CheckIn, :count)
      end

      it "returns unprocessable_content" do
        post location_checkin_path(location), params: blank_params

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "re-renders the form with an error" do
        post location_checkin_path(location), params: blank_params

        expect(response.body).to include("Check in as a guest")
      end
    end

    context "with an unknown location id" do
      it "returns 404" do
        post location_checkin_path(location_hashid: "nonexistent"), params: guest_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
