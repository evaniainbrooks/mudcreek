require "rails_helper"

RSpec.describe "Admin::Listings::DeliveryMethodSets::DeliveryMethods", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "delivery_manager", description: "Manage deliveries").tap do |r|
      r.permissions.create!(resource: "Listings::Delivery", action: "create")
      r.permissions.create!(resource: "Listings::Delivery", action: "destroy")
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "show")
    end
  end

  let(:user)                { create(:user, role: role) }
  let!(:delivery_method)    { create(:delivery_method) }
  let!(:delivery_method_set) { create(:listings_delivery_method_set) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/delivery_method_sets/:delivery_method_set_id/delivery_methods" do
    def post_delivery_method
      post admin_listings_delivery_method_set_delivery_methods_path(delivery_method_set),
        params: { delivery_method_id: delivery_method.id }
    end

    it "adds the delivery method to the set" do
      expect { post_delivery_method }.to change { delivery_method_set.reload.delivery_method_ids.count }.by(1)
    end

    it "redirects to the set show page with a notice" do
      post_delivery_method

      expect(response).to redirect_to(admin_listings_delivery_method_set_path(delivery_method_set))
      expect(flash[:notice]).to include(delivery_method.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post_delivery_method

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_delivery", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { post_delivery_method }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/listings/delivery_method_sets/:delivery_method_set_id/delivery_methods/:id" do
    let!(:delivery) { delivery_method_set.deliveries.create!(delivery_method: delivery_method) }

    it "removes the delivery method from the set" do
      expect {
        delete admin_listings_delivery_method_set_delivery_method_path(delivery_method_set, delivery)
      }.to change { delivery_method_set.reload.delivery_method_ids.count }.by(-1)
    end

    it "redirects to the set show page with a notice" do
      delete admin_listings_delivery_method_set_delivery_method_path(delivery_method_set, delivery)

      expect(response).to redirect_to(admin_listings_delivery_method_set_path(delivery_method_set))
      expect(flash[:notice]).to include(delivery_method.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_listings_delivery_method_set_delivery_method_path(delivery_method_set, delivery)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
