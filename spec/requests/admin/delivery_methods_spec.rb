require "rails_helper"

RSpec.describe "Admin::DeliveryMethods", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "delivery_manager", description: "Manage delivery methods").tap do |r|
      r.permissions.create!(resource: "DeliveryMethod", action: "index")
      r.permissions.create!(resource: "DeliveryMethod", action: "create")
      r.permissions.create!(resource: "DeliveryMethod", action: "update")
      r.permissions.create!(resource: "DeliveryMethod", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:delivery_method) { create(:delivery_method) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/delivery_methods" do
    it "returns 200" do
      get admin_delivery_methods_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the delivery method in the response" do
      get admin_delivery_methods_path

      expect(response.body).to include(delivery_method.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_delivery_methods_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_delivery", description: "No delivery access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_delivery_methods_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/delivery_methods" do
    context "with valid params" do
      it "creates a new delivery method" do
        expect {
          post admin_delivery_methods_path, params: { delivery_method: { name: "Local Pickup", price: "0.00" } }
        }.to change(DeliveryMethod, :count).by(1)
      end

      it "defaults active to true" do
        post admin_delivery_methods_path, params: { delivery_method: { name: "Local Pickup", price: "0.00" } }

        expect(DeliveryMethod.last).to be_active
      end

      it "redirects to the index with a notice" do
        post admin_delivery_methods_path, params: { delivery_method: { name: "Local Pickup", price: "0.00" } }

        expect(response).to redirect_to(admin_delivery_methods_path)
        expect(flash[:notice]).to include("Local Pickup")
      end

      it "stores the price in cents" do
        post admin_delivery_methods_path, params: { delivery_method: { name: "Standard Shipping", price: "15.00" } }

        expect(DeliveryMethod.last.price_cents).to eq(1500)
      end
    end

    context "with a duplicate name" do
      it "does not create a delivery method" do
        expect {
          post admin_delivery_methods_path, params: { delivery_method: { name: delivery_method.name, price: "0.00" } }
        }.not_to change(DeliveryMethod, :count)
      end

      it "re-renders the index with unprocessable entity status" do
        post admin_delivery_methods_path, params: { delivery_method: { name: delivery_method.name, price: "0.00" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a missing name" do
      it "does not create a delivery method" do
        expect {
          post admin_delivery_methods_path, params: { delivery_method: { name: "", price: "0.00" } }
        }.not_to change(DeliveryMethod, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_delivery_methods_path, params: { delivery_method: { name: "Pickup", price: "0.00" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_delivery", description: "Read-only delivery access").tap do |r|
          r.permissions.create!(resource: "DeliveryMethod", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_delivery_methods_path, params: { delivery_method: { name: "Pickup", price: "0.00" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/delivery_methods/:id" do
    context "updating the name" do
      it "changes the name" do
        patch admin_delivery_method_path(delivery_method), params: { delivery_method: { name: "Express Shipping" } }

        expect(delivery_method.reload.name).to eq("Express Shipping")
      end

      it "responds with a turbo stream" do
        patch admin_delivery_method_path(delivery_method),
          params: { delivery_method: { name: "Express Shipping" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "updating the price" do
      it "changes price_cents" do
        patch admin_delivery_method_path(delivery_method), params: { delivery_method: { price: "9.99" } }

        expect(delivery_method.reload.price_cents).to eq(999)
      end
    end

    context "toggling active to false" do
      it "deactivates the delivery method" do
        patch admin_delivery_method_path(delivery_method), params: { delivery_method: { active: false } }

        expect(delivery_method.reload).not_to be_active
      end
    end

    context "toggling active to true" do
      let!(:delivery_method) { create(:delivery_method, :inactive) }

      it "activates the delivery method" do
        patch admin_delivery_method_path(delivery_method), params: { delivery_method: { active: true } }

        expect(delivery_method.reload).to be_active
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_delivery_method_path(delivery_method), params: { delivery_method: { name: "Pickup" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_delivery", description: "Read-only delivery access").tap do |r|
          r.permissions.create!(resource: "DeliveryMethod", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_delivery_method_path(delivery_method), params: { delivery_method: { name: "Pickup" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/delivery_methods/:id" do
    it "destroys the delivery method" do
      expect {
        delete admin_delivery_method_path(delivery_method)
      }.to change(DeliveryMethod, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_delivery_method_path(delivery_method)

      expect(response).to redirect_to(admin_delivery_methods_path)
      expect(flash[:notice]).to include(delivery_method.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_delivery_method_path(delivery_method)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_delivery", description: "Read-only delivery access").tap do |r|
          r.permissions.create!(resource: "DeliveryMethod", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_delivery_method_path(delivery_method)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
