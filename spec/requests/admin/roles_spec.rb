require "rails_helper"

RSpec.describe "Admin::Roles", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "role_manager", description: "Manage roles").tap do |r|
      r.permissions.create!(resource: "Role",       action: "index")
      r.permissions.create!(resource: "Role",       action: "create")
      r.permissions.create!(resource: "Role",       action: "destroy")
      r.permissions.create!(resource: "Permission", action: "index")
      r.permissions.create!(resource: "Permission", action: "create")
      r.permissions.create!(resource: "Permission", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/roles" do
    it "returns 200 and lists the role" do
      get admin_roles_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("role_manager")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_roles_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_roles", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_roles_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/roles" do
    it "creates a role and redirects to index" do
      expect {
        post admin_roles_path, params: { role: { name: "new_role", description: "A new role" } }
      }.to change(Role, :count).by(1)

      expect(response).to redirect_to(admin_roles_path)
    end

    it "re-renders index with unprocessable_content on blank name" do
      post admin_roles_path, params: { role: { name: "", description: "Missing name" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_roles_path, params: { role: { name: "blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/roles/:id" do
    let!(:target_role) { Role.create!(name: "deletable", description: "To be deleted") }

    it "destroys the role and redirects to index" do
      expect {
        delete admin_role_path(target_role)
      }.to change(Role, :count).by(-1)

      expect(response).to redirect_to(admin_roles_path)
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/roles/:id/permissions" do
    it "returns 200 and lists permissions" do
      get admin_role_permissions_path(role)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Role")
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/roles/:id/permissions" do
    let!(:target_role) { Role.create!(name: "empty_role", description: "No permissions") }

    it "adds a permission and redirects" do
      expect {
        post admin_role_permissions_path(target_role),
          params: { permission: { resource: "Listing", action: "index" } }
      }.to change { target_role.permissions.count }.by(1)

      expect(response).to redirect_to(admin_role_permissions_path(target_role))
    end

    it "redirects with alert on invalid permission" do
      post admin_role_permissions_path(target_role),
        params: { permission: { resource: "NonExistent", action: "index" } }

      expect(response).to redirect_to(admin_role_permissions_path(target_role))
      expect(flash[:alert]).to be_present
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/roles/:id/permissions/:permission_id" do
    let!(:target_role) { Role.create!(name: "perm_role", description: "Has permissions") }
    let!(:permission)  { target_role.permissions.create!(resource: "Listing", action: "index") }

    it "destroys the permission and redirects" do
      expect {
        delete admin_role_permission_path(target_role, permission)
      }.to change { target_role.permissions.count }.by(-1)

      expect(response).to redirect_to(admin_role_permissions_path(target_role))
    end
  end
end
