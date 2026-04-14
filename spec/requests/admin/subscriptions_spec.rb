require "rails_helper"

RSpec.describe "Admin::Subscriptions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "subscription_manager", description: "Manage subscriptions").tap do |r|
      r.permissions.create!(resource: "Subscription", action: "show")
      r.permissions.create!(resource: "Subscription", action: "create")
      r.permissions.create!(resource: "Subscription", action: "update")
      r.permissions.create!(resource: "SubscriptionPlan", action: "show")
    end
  end

  let(:admin) { create(:user, role: role) }
  let!(:plan) { create(:subscription_plan) }
  let!(:target_user) { create(:user) }
  let!(:subscription) { create(:subscription, user: target_user, subscription_plan: plan) }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  describe "GET /admin/subscriptions/:id" do
    it "returns 200" do
      get admin_subscription_path(subscription)

      expect(response).to have_http_status(:ok)
    end

    it "displays the subscription status" do
      get admin_subscription_path(subscription)

      expect(response.body).to include("active")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_subscription_path(subscription)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_subscriptions", description: "No subscription access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_subscription_path(subscription) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/subscriptions" do
    let(:other_plan) { create(:subscription_plan) }
    let(:other_user) { create(:user) }
    let(:valid_params) do
      {
        subscription: {
          user_id: other_user.id,
          subscription_plan_id: other_plan.id,
          renews_at: 1.month.from_now.to_date
        }
      }
    end

    it "creates a new subscription" do
      expect {
        post admin_subscriptions_path, params: valid_params
      }.to change(Subscription, :count).by(1)
    end

    it "redirects to the subscription plan page with a notice" do
      post admin_subscriptions_path, params: valid_params

      expect(response).to redirect_to(admin_subscription_plan_path(other_plan))
      expect(flash[:notice]).to include("successfully created")
    end

    context "when the user already has a subscription to that plan" do
      it "does not create a duplicate subscription" do
        expect {
          post admin_subscriptions_path, params: {
            subscription: {
              user_id: target_user.id,
              subscription_plan_id: plan.id,
              renews_at: 1.month.from_now.to_date
            }
          }
        }.not_to change(Subscription, :count)
      end

      it "returns 422" do
        post admin_subscriptions_path, params: {
          subscription: {
            user_id: target_user.id,
            subscription_plan_id: plan.id,
            renews_at: 1.month.from_now.to_date
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a missing renews_at" do
      it "does not create a subscription" do
        expect {
          post admin_subscriptions_path, params: {
            subscription: { user_id: other_user.id, subscription_plan_id: other_plan.id, renews_at: "" }
          }
        }.not_to change(Subscription, :count)
      end

      it "returns 422" do
        post admin_subscriptions_path, params: {
          subscription: { user_id: other_user.id, subscription_plan_id: other_plan.id, renews_at: "" }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_subscriptions_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_subs", description: "Read-only subscription access").tap do |r|
          r.permissions.create!(resource: "Subscription", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_subscriptions_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/subscriptions/:id" do
    it "updates the subscription status" do
      patch admin_subscription_path(subscription), params: { subscription: { status: "lapsed", renews_at: subscription.renews_at } }

      expect(subscription.reload.status).to eq("lapsed")
    end

    it "redirects to the subscription page with a notice" do
      patch admin_subscription_path(subscription), params: { subscription: { status: "lapsed", renews_at: subscription.renews_at } }

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(flash[:notice]).to include("successfully updated")
    end

    it "updates renews_at" do
      new_date = 2.months.from_now.to_date
      patch admin_subscription_path(subscription), params: { subscription: { status: subscription.status, renews_at: new_date } }

      expect(subscription.reload.renews_at).to eq(new_date)
    end

    context "with invalid params" do
      it "returns 422" do
        patch admin_subscription_path(subscription), params: { subscription: { status: subscription.status, renews_at: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_subscription_path(subscription), params: { subscription: { status: "lapsed", renews_at: subscription.renews_at } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_subs", description: "Read-only subscription access").tap do |r|
          r.permissions.create!(resource: "Subscription", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_subscription_path(subscription), params: { subscription: { status: "lapsed", renews_at: subscription.renews_at } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
