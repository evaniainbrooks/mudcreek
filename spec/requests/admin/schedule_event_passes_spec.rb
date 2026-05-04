require "rails_helper"

RSpec.describe "Admin::ScheduleEventPasses", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  # ScheduleEventPass is not in Permission::RESOURCES, so tests use super_admin.
  let(:admin)       { create(:user, :super_admin) }
  let(:pass_holder) { create(:user) }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/schedule_event_passes" do
    let!(:pass) { ScheduleEventPass.create!(user: pass_holder, credits_remaining: 5, tenant: Current.tenant) }

    it "returns 200" do
      get admin_schedule_event_passes_path

      expect(response).to have_http_status(:ok)
    end

    it "lists passes across all users" do
      get admin_schedule_event_passes_path

      expect(response.body).to include(pass_holder.email_address)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_schedule_event_passes_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/schedule_event_passes?user_id=:user_id" do
    let!(:pass) { ScheduleEventPass.create!(user: pass_holder, credits_remaining: 3, tenant: Current.tenant) }

    it "returns 200" do
      get admin_schedule_event_passes_path(user_id: pass_holder.id)

      expect(response).to have_http_status(:ok)
    end

    it "shows passes for the given user (Member column is suppressed when user is set)" do
      get admin_schedule_event_passes_path(user_id: pass_holder.id)

      expect(response.body).not_to include("No passes issued yet")
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/schedule_event_passes/new" do
    it "returns 200" do
      get new_admin_schedule_event_pass_path

      expect(response).to have_http_status(:ok)
    end

    it "returns 200 when scoped to a user" do
      get new_admin_schedule_event_pass_path(user_id: pass_holder.id)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/schedule_event_passes (with user_id)" do
    let(:valid_params) { { user_id: pass_holder.id, schedule_event_pass: { credits_remaining: 10 } } }

    it "creates a pass" do
      expect {
        post admin_schedule_event_passes_path, params: valid_params
      }.to change(ScheduleEventPass, :count).by(1)
    end

    it "associates the pass with the specified user" do
      post admin_schedule_event_passes_path, params: valid_params

      expect(ScheduleEventPass.last.user).to eq(pass_holder)
    end

    it "redirects with a notice" do
      post admin_schedule_event_passes_path, params: valid_params

      expect(flash[:notice]).to eq("Pass issued.")
    end

    context "with a negative credits value" do
      it "returns unprocessable_content" do
        post admin_schedule_event_passes_path,
             params: { user_id: pass_holder.id, schedule_event_pass: { credits_remaining: -1 } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a pass" do
        expect {
          post admin_schedule_event_passes_path,
               params: { user_id: pass_holder.id, schedule_event_pass: { credits_remaining: -1 } }
        }.not_to change(ScheduleEventPass, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_schedule_event_passes_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/schedule_event_passes/:id" do
    let!(:pass) { ScheduleEventPass.create!(user: pass_holder, credits_remaining: 5, tenant: Current.tenant) }

    it "destroys the pass" do
      expect {
        delete admin_schedule_event_pass_path(pass)
      }.to change(ScheduleEventPass, :count).by(-1)
    end

    it "redirects with a notice" do
      delete admin_schedule_event_pass_path(pass)

      expect(flash[:notice]).to eq("Pass removed.")
    end
  end
end
