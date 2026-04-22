require "rails_helper"

RSpec.describe "Admin::Kiosks", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "kiosk_manager", description: "Manage kiosks").tap do |r|
      r.permissions.create!(resource: "Location", action: "show")
      r.permissions.create!(resource: "Kiosk",    action: "update")
    end
  end

  let(:user)      { create(:user, role: role) }
  let!(:location) { create(:location, name: "Main Gym") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid (kiosk tab renders)" do
    it "returns 200 and includes the kiosk form" do
      get admin_location_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Kiosk")
    end

    it "points the form at the PATCH endpoint even when no kiosk record exists yet" do
      get admin_location_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(admin_location_kiosk_path(location))
    end

    it "renders the kiosk form when a kiosk already exists" do
      location.create_kiosk!

      get admin_location_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Save Kiosk")
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/locations/:location_hashid/kiosk" do
    context "with valid params" do
      it "redirects to the location show page" do
        patch admin_location_kiosk_path(location),
              params: { kiosk: { slide_timeout: 10, background_tint_opacity: 0.5 } }

        expect(response).to redirect_to(admin_location_path(location))
      end

      it "updates kiosk attributes" do
        patch admin_location_kiosk_path(location),
              params: { kiosk: { slide_timeout: 15, background_tint_opacity: 0.3 } }

        kiosk = location.reload.kiosk
        expect(kiosk.slide_timeout).to eq(15)
        expect(kiosk.background_tint_opacity).to be_within(0.01).of(0.3)
      end

      it "sets a flash notice" do
        patch admin_location_kiosk_path(location),
              params: { kiosk: { slide_timeout: 5 } }

        expect(flash[:notice]).to eq("Kiosk updated.")
      end

      it "creates the kiosk if one does not yet exist" do
        patch admin_location_kiosk_path(location), params: { kiosk: { slide_timeout: 5 } }

        expect(Kiosk.unscoped.where(location: location).count).to eq(1)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_location_kiosk_path(location), params: { kiosk: { slide_timeout: 5 } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the kiosk update permission" do
      let(:role) do
        Role.create!(name: "location_only", description: "Location only").tap do |r|
          r.permissions.create!(resource: "Location", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_location_kiosk_path(location), params: { kiosk: { slide_timeout: 5 } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
