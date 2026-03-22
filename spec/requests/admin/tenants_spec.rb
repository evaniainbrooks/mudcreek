require "rails_helper"

RSpec.describe "Admin::Tenants", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "tenant_manager", description: "Manage tenant").tap do |r|
      r.permissions.create!(resource: "Tenant", action: "show")
      r.permissions.create!(resource: "Tenant", action: "update")
    end
  end

  let(:viewer) { create(:user, role: role) }
  let!(:target) { create(:user) }

  before { post session_path, params: { email_address: viewer.email_address, password: "password" } }

  describe "GET /admin/tenant" do
    it "returns 200", :aggregate_failures do
      get admin_tenant_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Current.tenant.name)
    end
  end

  describe "PATCH /admin/tenant" do
    it "returns 200", :aggregate_failures do
      patch(admin_tenant_path, params: { tenant: { name: "New Name" } })

      expect(response).to have_http_status(:found)

      get admin_tenant_path

      expect(response.body).to include("New Name")
    end

    it "updates address" do
      patch(admin_tenant_path, params: { tenant: { address_attributes: { city: "Calgary" } } })

      expect(response).to have_http_status(:found)

      get admin_tenant_path

      expect(response.body).to include("Calgary")
    end

    context "with a missing name" do
      it "does not update the tenant" do
        expect {
          patch admin_tenant_path, params: { tenant: { name: "" } }
        }.not_to change { Current.tenant.reload.name }
      end

      it "re-renders the show page with unprocessable entity status" do
        patch admin_tenant_path, params: { tenant: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_tenant_path, params: { tenant: { name: "New Name" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "read_only_tenant", description: "Read-only").tap { |r| r.permissions.create!(resource: "Tenant", action: "show") } }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_tenant_path, params: { tenant: { name: "New Name" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/tenant" do
    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_tenant_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_tenant_show", description: "No show") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_tenant_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
