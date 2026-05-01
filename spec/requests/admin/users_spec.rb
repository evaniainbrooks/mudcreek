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
      r.permissions.create!(resource: "User", action: "create")
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

  describe "GET /admin/users/:id?tab=checkins" do
    let!(:location) { create(:location) }

    it "returns 200 and renders the check-ins tab" do
      get admin_user_path(target, tab: "checkins")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check-ins")
    end

    it "lists check-ins for the user" do
      ci = create(:check_in, user: target, location: location)

      get admin_user_path(target, tab: "checkins")

      expect(response.body).to include(location.name)
    end

    it "shows no check-ins message when empty" do
      get admin_user_path(target, tab: "checkins")

      expect(response.body).to include("No check-ins yet")
    end

    context "with more than one page of check-ins" do
      before { 21.times { create(:check_in, user: target, location: location) } }

      it "returns 200 on page 1" do
        get admin_user_path(target, tab: "checkins", page: 1)

        expect(response).to have_http_status(:ok)
      end

      it "renders a Next link on page 1" do
        get admin_user_path(target, tab: "checkins", page: 1)

        expect(response.body).to include("page=2")
        expect(response.body).to include("Next")
      end

      it "renders a Previous link on page 2" do
        get admin_user_path(target, tab: "checkins", page: 2)

        expect(response.body).to include("page=1")
        expect(response.body).to include("Previous")
      end

      it "does not render a Previous link on page 1" do
        get admin_user_path(target, tab: "checkins", page: 1)

        expect(response.body).not_to include("Previous")
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

  describe "GET /admin/users/new" do
    it "returns 200" do
      get new_admin_user_path

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get new_admin_user_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "User", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get new_admin_user_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      {
        user: {
          first_name: "Jane",
          last_name: "Doe",
          email_address: "jane@example.com",
          password: "secret123",
          password_confirmation: "secret123"
        }
      }
    end

    it "creates a new user" do
      expect {
        post admin_users_path, params: valid_params
      }.to change(User, :count).by(1)
    end

    it "redirects to the new user's page with a notice" do
      post admin_users_path, params: valid_params

      created = User.find_by!(email_address: "jane@example.com")
      expect(response).to redirect_to(admin_user_path(created))
      expect(flash[:notice]).to eq("User was successfully created.")
    end

    it "sets created_by_id to the current admin" do
      post admin_users_path, params: valid_params

      created = User.find_by!(email_address: "jane@example.com")
      expect(created.created_by_id).to eq(viewer.id)
    end

    context "with invalid params" do
      it "returns 422" do
        post admin_users_path, params: { user: { first_name: "", last_name: "", email_address: "", password: "x" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a user" do
        expect {
          post admin_users_path, params: { user: { email_address: "" } }
        }.not_to change(User, :count)
      end
    end

    context "with a duplicate email address" do
      it "returns 422" do
        post admin_users_path, params: { user: valid_params[:user].merge(email_address: target.email_address) }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_users_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "User", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_users_path, params: valid_params }.to raise_error(Pundit::NotAuthorizedError)
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

    context "when setting verification status to validated" do
      context "and the user has no existing verification" do
        it "creates a verification record" do
          expect {
            patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "validated" } }
          }.to change { Users::Verification.count }.by(1)
        end

        it "sets the status to validated" do
          patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "validated" } }

          expect(target.reload.verification.status).to eq("validated")
        end

        it "records the validating admin as validated_by" do
          patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "validated" } }

          expect(target.reload.verification.validated_by).to eq(viewer)
        end
      end

      context "and the user already has a verification" do
        before { create(:users_verification, user: target) }

        it "does not create a duplicate verification record" do
          expect {
            patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "validated" } }
          }.not_to change { Users::Verification.count }
        end

        it "updates the status to validated" do
          patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "validated" } }

          expect(target.reload.verification.status).to eq("validated")
        end
      end
    end

    context "when setting verification status to not_validated" do
      before { create(:users_verification, :validated, user: target) }

      it "updates the status to not_validated" do
        patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "not_validated" } }

        expect(target.reload.verification.status).to eq("not_validated")
      end

      it "clears validated_by" do
        patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "not_validated" } }

        expect(target.reload.verification.validated_by).to be_nil
      end
    end

    context "when verification_status is blank" do
      it "does not create a verification record" do
        expect {
          patch admin_user_path(target), params: { user: { first_name: target.first_name, last_name: target.last_name, email_address: target.email_address, verification_status: "" } }
        }.not_to change { Users::Verification.count }
      end
    end

    context "with an invalid email" do
      it "returns 422" do
        patch admin_user_path(target), params: { user: { email_address: "" } }

        expect(response).to have_http_status(:unprocessable_content)
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

  describe "POST /admin/users/:id/resend_activation" do
    context "when the target user is not activated" do
      it "enqueues an activation email" do
        expect {
          post resend_activation_admin_user_path(target)
        }.to have_enqueued_mail(RegistrationsMailer, :activate).with(target)
      end

      it "redirects to the users index with a notice" do
        post resend_activation_admin_user_path(target)

        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to include(target.email_address)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post resend_activation_admin_user_path(target)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_resend", description: "Read only").tap do |r|
          r.permissions.create!(resource: "User", action: "index")
          r.permissions.create!(resource: "User", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post resend_activation_admin_user_path(target)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
