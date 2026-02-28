require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "user_manager", description: "Manage users").tap do |r|
      r.permissions.create!(resource: "User", action: "index")
      r.permissions.create!(resource: "User", action: "show")
    end
  end

  let(:viewer) { create(:user, role: role) }
  let!(:target) { create(:user) }

  before { post session_path, params: { email_address: viewer.email_address, password: "password" } }

  describe "GET /admin/users/:id" do
    it "returns 200" do
      get admin_user_path(target)

      expect(response).to have_http_status(:ok)
    end

    it "displays the user's name" do
      get admin_user_path(target)

      expect(response.body).to include(target.name)
    end

    it "displays the user's email" do
      get admin_user_path(target)

      expect(response.body).to include(target.email_address)
    end

    context "when the user is activated" do
      let!(:target) { create(:user, activated_at: 2.days.ago) }

      it "shows the activated badge" do
        get admin_user_path(target)

        expect(response.body).to include("Activated")
      end
    end

    context "when the user is not activated" do
      let!(:target) { create(:user, :unactivated) }

      it "shows the pending activation badge" do
        get admin_user_path(target)

        expect(response.body).to include("Pending activation")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_user_path(target)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_users", description: "No user access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_user_path(target) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
