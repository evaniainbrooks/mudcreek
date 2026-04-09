require "rails_helper"

RSpec.describe "Admin::Locations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "location_manager", description: "Manage locations").tap do |r|
      r.permissions.create!(resource: "Location", action: "index")
      r.permissions.create!(resource: "Location", action: "show")
      r.permissions.create!(resource: "Location", action: "create")
      r.permissions.create!(resource: "Location", action: "update")
      r.permissions.create!(resource: "Location", action: "destroy")
    end
  end

  let(:user)      { create(:user, role: role) }
  let!(:location) { create(:location, name: "Main Gym") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations" do
    it "returns 200 and lists the location" do
      get admin_locations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Gym")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_locations_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_locations", description: "No location access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_locations_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:id" do
    it "returns 200 and shows the location name" do
      get admin_location_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Main Gym")
    end

    it "shows total check-in count" do
      create_list(:check_in, 3, location: location)

      get admin_location_path(location)

      expect(response.body).to include("3")
    end

    it "shows per-user check-in rows" do
      visitor = create(:user, first_name: "Alice", last_name: "Smith")
      create(:check_in, location: location, user: visitor)

      get admin_location_path(location)

      expect(response.body).to include("Alice Smith")
    end

    it "shows guest check-in rows in the by-user table" do
      create(:check_in, :guest, location: location, guest_name: "Bob Guest")

      get admin_location_path(location)

      expect(response.body).to include("Bob Guest")
      expect(response.body).to include("Guest")
    end

    it "renders a QR code for the check-in URL" do
      location.create_qr_code!(
        name: "#{location.name} Check-in",
        destination_url: location_checkin_url(location),
        active: true
      )

      get admin_location_path(location)

      expect(response.body).to include("svg")
      expect(response.body).to include(qr_redirect_url(location.qr_code))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_location_path(location)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) do
        Role.create!(name: "index_only", description: "Index only").tap do |r|
          r.permissions.create!(resource: "Location", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_location_path(location) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/new" do
    it "returns 200" do
      get new_admin_location_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:id/edit" do
    it "returns 200" do
      get edit_admin_location_path(location)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/locations" do
    context "with a name only" do
      it "creates the location" do
        expect {
          post admin_locations_path, params: { location: { name: "New Spot" } }
        }.to change(Location, :count).by(1)
      end

      it "redirects to the location show page" do
        post admin_locations_path, params: { location: { name: "New Spot" } }

        expect(response).to redirect_to(admin_location_path(Location.last))
      end

      it "does not create an address" do
        expect {
          post admin_locations_path, params: { location: { name: "New Spot" } }
        }.not_to change(Address, :count)
      end
    end

    context "with address attributes" do
      let(:params) do
        {
          location: {
            name: "Gym with Address",
            address_attributes: {
              street_address: "456 Oak Ave",
              city:           "Ottawa",
              province:       "ON",
              postal_code:    "K2P 1L4",
              country:        "CA"
            }
          }
        }
      end

      it "creates the location and its address" do
        expect {
          post admin_locations_path, params: params
        }.to change(Location, :count).by(1).and change(Address, :count).by(1)
      end

      it "persists the address fields" do
        post admin_locations_path, params: params

        address = Location.last.address
        expect(address.city).to eq("Ottawa")
        expect(address.street_address).to eq("456 Oak Ave")
      end
    end

    context "with a blank name" do
      it "does not create a location" do
        expect {
          post admin_locations_path, params: { location: { name: "" } }
        }.not_to change(Location, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_locations_path, params: { location: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_locations_path, params: { location: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_locations", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Location", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_locations_path, params: { location: { name: "Blocked" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/locations/:id" do
    context "with valid params" do
      it "updates the location name" do
        patch admin_location_path(location), params: { location: { name: "Renamed Gym" } }

        expect(location.reload.name).to eq("Renamed Gym")
      end

      it "redirects to the show page" do
        patch admin_location_path(location), params: { location: { name: "Renamed Gym" } }

        expect(response).to redirect_to(admin_location_path(location))
      end
    end

    context "adding an address to a location that has none" do
      it "creates an address" do
        expect {
          patch admin_location_path(location), params: {
            location: {
              address_attributes: { street_address: "789 Pine Rd", city: "Toronto", country: "CA" }
            }
          }
        }.to change(Address, :count).by(1)
      end
    end

    context "updating an existing address" do
      before { location.create_address!(address_type: "profile", city: "Ottawa", country: "CA") }

      it "updates the address city" do
        patch admin_location_path(location), params: {
          location: {
            address_attributes: { id: location.address.id, city: "Toronto" }
          }
        }

        expect(location.address.reload.city).to eq("Toronto")
      end
    end

    context "with a blank name" do
      it "re-renders edit with unprocessable_content" do
        patch admin_location_path(location), params: { location: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_locations", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Location", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_location_path(location), params: { location: { name: "Blocked" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/locations/:id" do
    it "destroys the location" do
      expect {
        delete admin_location_path(location)
      }.to change(Location, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_location_path(location)

      expect(response).to redirect_to(admin_locations_path)
      expect(flash[:notice]).to be_present
    end

    it "destroys associated check-ins" do
      create(:check_in, location: location)

      expect {
        delete admin_location_path(location)
      }.to change(CheckIn, :count).by(-1)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_location_path(location)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_locations", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Location", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_location_path(location)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
