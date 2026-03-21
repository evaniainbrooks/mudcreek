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
      r.permissions.create!(resource: "User", action: "update")
    end
  end

  let(:viewer) { create(:user, role: role) }
  let!(:target) { create(:user) }

  before { post session_path, params: { email_address: viewer.email_address, password: "password" } }

  describe "GET /admin/users" do
    it "returns 200" do
      get admin_users_path

      expect(response).to have_http_status(:ok)
    end

    it "lists users" do
      get admin_users_path

      expect(response.body).to include(target.email_address)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_users_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_users", description: "No user access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_users_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

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

  describe "PATCH /admin/users/:id" do
    it "updates the user's name" do
      patch admin_user_path(target), params: { user: { first_name: "Updated", last_name: "Name" } }

      expect(target.reload.first_name).to eq("Updated")
      expect(target.reload.last_name).to eq("Name")
    end

    it "redirects with a notice on success" do
      patch admin_user_path(target), params: { user: { first_name: "Updated", last_name: "Name" } }

      expect(response).to redirect_to(admin_user_path(target))
      expect(flash[:notice]).to eq("User updated.")
    end

    context "when activating the user" do
      let!(:inactive_user) { create(:user, :unactivated) }

      it "sets activated_at" do
        patch admin_user_path(inactive_user), params: { user: { first_name: inactive_user.first_name, last_name: inactive_user.last_name, email_address: inactive_user.email_address, activated: "1" } }

        expect(inactive_user.reload.activated_at).to be_present
      end
    end

    context "when deactivating the user" do
      it "clears activated_at" do
        patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, activated: "0" } }

        expect(target.reload.activated_at).to be_nil
      end
    end

    context "with an invalid email" do
      it "returns 422" do
        patch admin_user_path(target), params: { user: { email_address: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_user_path(target), params: { user: { first_name: "Updated", last_name: "Name" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "User", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_user_path(target), params: { user: { first_name: "Updated", last_name: "Name" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
