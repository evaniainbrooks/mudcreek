require "rails_helper"

RSpec.describe "Admin::SubscriptionUsers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "subscription_user_manager", description: "Manage subscription users").tap do |r|
      r.permissions.create!(resource: "SubscriptionUser", action: "create")
      r.permissions.create!(resource: "SubscriptionUser", action: "destroy")
    end
  end

  let(:admin) { create(:user, role: role) }
  let!(:plan) { create(:subscription_plan) }
  let!(:subscription) { create(:subscription, subscription_plan: plan) }
  let!(:new_user) { create(:user) }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  describe "POST /admin/subscriptions/:subscription_id/subscription_users" do
    let(:valid_params) { { subscription_user: { user_id: new_user.id } } }

    it "adds the user to the subscription" do
      expect {
        post admin_subscription_subscription_users_path(subscription), params: valid_params
      }.to change(SubscriptionUser, :count).by(1)
    end

    it "redirects to the subscription page with a notice" do
      post admin_subscription_subscription_users_path(subscription), params: valid_params

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(flash[:notice]).to include("User added")
    end

    context "when the user is already on the subscription" do
      before { subscription.subscription_users.create!(user: new_user) }

      it "does not add a duplicate" do
        expect {
          post admin_subscription_subscription_users_path(subscription), params: valid_params
        }.not_to change(SubscriptionUser, :count)
      end

      it "redirects with an alert" do
        post admin_subscription_subscription_users_path(subscription), params: valid_params

        expect(response).to redirect_to(admin_subscription_path(subscription))
        expect(flash[:alert]).to be_present
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_subscription_subscription_users_path(subscription), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_sub_user_create", description: "No subscription user create access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_subscription_subscription_users_path(subscription), params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/subscriptions/:subscription_id/subscription_users/:id" do
    let!(:other_user) { create(:user) }
    let!(:subscription_user) { subscription.subscription_users.create!(user: other_user) }

    it "removes the user from the subscription" do
      expect {
        delete admin_subscription_subscription_user_path(subscription, subscription_user)
      }.to change(SubscriptionUser, :count).by(-1)
    end

    it "redirects to the subscription page with a notice" do
      delete admin_subscription_subscription_user_path(subscription, subscription_user)

      expect(response).to redirect_to(admin_subscription_path(subscription))
      expect(flash[:notice]).to include("User removed")
    end

    context "when the subscription_user is the primary contact" do
      before { subscription_user.update!(primary_contact: true) }

      it "does not remove the user" do
        expect {
          delete admin_subscription_subscription_user_path(subscription, subscription_user)
        }.not_to change(SubscriptionUser, :count)
      end

      it "redirects with an alert about the primary contact" do
        delete admin_subscription_subscription_user_path(subscription, subscription_user)

        expect(response).to redirect_to(admin_subscription_path(subscription))
        expect(flash[:alert]).to include("primary contact")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_subscription_subscription_user_path(subscription, subscription_user)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "create_only_sub_users", description: "Create-only subscription user access").tap do |r|
          r.permissions.create!(resource: "SubscriptionUser", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_subscription_subscription_user_path(subscription, subscription_user)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
