require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user, :super_admin) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin" do
    it "returns 200" do
      get admin_root_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the admin heading" do
      get admin_root_path

      expect(response.body).to include("Admin")
    end

    it "greets the user by first name" do
      get admin_root_path

      expect(response.body).to include("Welcome back, #{user.first_name}.")
    end

    it "shows section links the user has access to" do
      get admin_root_path

      expect(response.body).to include("Listings")
      expect(response.body).to include("Orders")
      expect(response.body).to include("Users")
    end

    context "when the user has limited permissions" do
      let(:user) do
        role = Role.create!(name: "listings_only", description: "Listings only").tap do |r|
          r.permissions.create!(resource: "Listing", action: "index")
        end
        create(:user, role: role)
      end

      it "shows only the sections the user can access" do
        get admin_root_path

        expect(response.body).to include("Listings")
        expect(response.body).not_to include("Orders")
        expect(response.body).not_to include("Users")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_root_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
