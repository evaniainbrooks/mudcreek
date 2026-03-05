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
  end
end
