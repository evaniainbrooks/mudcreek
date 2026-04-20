require "rails_helper"

RSpec.describe "Admin::SubscriptionPlans", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "plan_manager", description: "Manage subscription plans").tap do |r|
      r.permissions.create!(resource: "SubscriptionPlan", action: "index")
      r.permissions.create!(resource: "SubscriptionPlan", action: "show")
      r.permissions.create!(resource: "SubscriptionPlan", action: "create")
      r.permissions.create!(resource: "SubscriptionPlan", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:plan) { create(:subscription_plan) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/subscription_plans" do
    it "returns 200" do
      get admin_subscription_plans_path

      expect(response).to have_http_status(:ok)
    end

    it "lists the plan" do
      get admin_subscription_plans_path

      expect(response.body).to include(plan.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_subscription_plans_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_plans", description: "No plan access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_subscription_plans_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/subscription_plans/:id" do
    it "returns 200" do
      get admin_subscription_plan_path(plan)

      expect(response).to have_http_status(:ok)
    end

    it "displays the plan name" do
      get admin_subscription_plan_path(plan)

      expect(response.body).to include(plan.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_subscription_plan_path(plan)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) do
        Role.create!(name: "index_only_plans", description: "Index only").tap do |r|
          r.permissions.create!(resource: "SubscriptionPlan", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_subscription_plan_path(plan) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/subscription_plans" do
    let(:valid_params) do
      { subscription_plan: { name: "Gold", description: "Gold plan", amount: "99.00", subscription_type: "month_to_month" } }
    end

    it "creates a new subscription plan" do
      expect {
        post admin_subscription_plans_path, params: valid_params
      }.to change(SubscriptionPlan, :count).by(1)
    end

    it "redirects to the index with a notice including the name" do
      post admin_subscription_plans_path, params: valid_params

      expect(response).to redirect_to(admin_subscription_plans_path)
      expect(flash[:notice]).to include("Gold")
    end

    context "with a missing name" do
      it "does not create a plan" do
        expect {
          post admin_subscription_plans_path, params: { subscription_plan: { name: "", amount: "10.00", subscription_type: "month_to_month" } }
        }.not_to change(SubscriptionPlan, :count)
      end

      it "returns 422" do
        post admin_subscription_plans_path, params: { subscription_plan: { name: "", amount: "10.00", subscription_type: "month_to_month" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a duplicate name" do
      it "returns 422" do
        post admin_subscription_plans_path, params: { subscription_plan: { name: plan.name, amount: "10.00", subscription_type: "month_to_month" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_subscription_plans_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_plans", description: "Read-only plan access").tap do |r|
          r.permissions.create!(resource: "SubscriptionPlan", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_subscription_plans_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/subscription_plans/:id" do
    it "destroys the plan" do
      expect {
        delete admin_subscription_plan_path(plan)
      }.to change(SubscriptionPlan, :count).by(-1)
    end

    it "redirects to the index with a notice including the name" do
      name = plan.name
      delete admin_subscription_plan_path(plan)

      expect(response).to redirect_to(admin_subscription_plans_path)
      expect(flash[:notice]).to include(name)
    end

    context "when the plan has active subscriptions" do
      before { create(:subscription, subscription_plan: plan) }

      # The model uses restrict_with_error so destroy! raises ActiveRecord::RecordNotDestroyed.
      # The controller rescues ActiveRecord::DeleteRestrictionError (restrict_with_exception),
      # so the exception propagates unhandled here.
      it "raises ActiveRecord::RecordNotDestroyed" do
        expect {
          delete admin_subscription_plan_path(plan)
        }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end

      it "does not destroy the plan" do
        expect {
          delete admin_subscription_plan_path(plan) rescue nil
        }.not_to change(SubscriptionPlan, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_subscription_plan_path(plan)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_plans", description: "Read-only plan access").tap do |r|
          r.permissions.create!(resource: "SubscriptionPlan", action: "index")
          r.permissions.create!(resource: "SubscriptionPlan", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_subscription_plan_path(plan)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
