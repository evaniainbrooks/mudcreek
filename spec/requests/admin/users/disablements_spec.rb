require "rails_helper"

RSpec.describe "Admin::Users::Disablements", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "user_manager", description: "Manage users").tap do |r|
      r.permissions.create!(resource: "User", action: "update")
    end
  end

  let(:admin)  { create(:user, role: role) }
  let!(:target) { create(:user, email_address: "alice@example.com") }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "POST /admin/users/:user_id/disablement" do
    it "redirects to the users index" do
      post admin_user_disablement_path(target)

      expect(response).to redirect_to(admin_users_path)
    end

    it "sets a flash notice containing the original email" do
      post admin_user_disablement_path(target)

      expect(flash[:notice]).to include("alice@example.com")
      expect(flash[:notice]).to include("disabled")
    end

    it "stores the original email in disabled_email_address" do
      post admin_user_disablement_path(target)

      expect(target.reload.disabled_email_address).to eq("alice@example.com")
    end

    it "sets disabled_at" do
      freeze_time do
        post admin_user_disablement_path(target)

        expect(target.reload.disabled_at).to be_within(1.second).of(Time.current)
      end
    end

    it "scrambles the email address so the account cannot be used to sign in" do
      post admin_user_disablement_path(target)

      expect(target.reload.email_address).not_to eq("alice@example.com")
    end

    it "destroys all sessions for the user" do
      target.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
      post admin_user_disablement_path(target)

      expect(target.sessions.count).to eq(0)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_user_disablement_path(target)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_user_disablement_path(target) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/users/:user_id/disablement" do
    before do
      target.update!(
        disabled_email_address: "alice@example.com",
        disabled_at: 1.day.ago,
        email_address: "disabled_abc123@example.com"
      )
    end

    it "redirects to the users index" do
      delete admin_user_disablement_path(target)

      expect(response).to redirect_to(admin_users_path)
    end

    it "restores the original email address" do
      delete admin_user_disablement_path(target)

      expect(target.reload.email_address).to eq("alice@example.com")
    end

    it "clears disabled_email_address" do
      delete admin_user_disablement_path(target)

      expect(target.reload.disabled_email_address).to be_nil
    end

    it "clears disabled_at" do
      delete admin_user_disablement_path(target)

      expect(target.reload.disabled_at).to be_nil
    end

    it "sets a flash notice containing the restored email" do
      delete admin_user_disablement_path(target)

      expect(flash[:notice]).to include("alice@example.com")
      expect(flash[:notice]).to include("re-enabled")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_user_disablement_path(target)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect { delete admin_user_disablement_path(target) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
