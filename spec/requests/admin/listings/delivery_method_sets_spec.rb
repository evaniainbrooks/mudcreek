require "rails_helper"

RSpec.describe "Admin::Listings::DeliveryMethodSets", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "dms_manager", description: "Manage delivery method sets").tap do |r|
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "index")
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "show")
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "create")
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "update")
      r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:delivery_method_set) { create(:listings_delivery_method_set) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/listings/delivery_method_sets" do
    it "returns 200" do
      get admin_listings_delivery_method_sets_path

      expect(response).to have_http_status(:ok)
    end

    it "lists existing sets" do
      get admin_listings_delivery_method_sets_path

      expect(response.body).to include(delivery_method_set.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_listings_delivery_method_sets_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_dms", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_listings_delivery_method_sets_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/listings/delivery_method_sets/:id" do
    it "returns 200" do
      get admin_listings_delivery_method_set_path(delivery_method_set)

      expect(response).to have_http_status(:ok)
    end

    it "displays the set name" do
      get admin_listings_delivery_method_set_path(delivery_method_set)

      expect(response.body).to include(delivery_method_set.name)
    end
  end

  describe "POST /admin/listings/delivery_method_sets" do
    context "with valid params" do
      it "creates a new delivery method set" do
        expect {
          post admin_listings_delivery_method_sets_path, params: { listings_delivery_method_set: { name: "Standard Shipping" } }
        }.to change(Listings::DeliveryMethodSet, :count).by(1)
      end

      it "redirects to the index with a notice" do
        post admin_listings_delivery_method_sets_path, params: { listings_delivery_method_set: { name: "Standard Shipping" } }

        expect(response).to redirect_to(admin_listings_delivery_method_sets_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with a blank name" do
      it "does not create a set" do
        expect {
          post admin_listings_delivery_method_sets_path, params: { listings_delivery_method_set: { name: "" } }
        }.not_to change(Listings::DeliveryMethodSet, :count)
      end

      it "re-renders the index with unprocessable_content" do
        post admin_listings_delivery_method_sets_path, params: { listings_delivery_method_set: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_dms", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Listings::DeliveryMethodSet", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listings_delivery_method_sets_path, params: { listings_delivery_method_set: { name: "New Set" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/listings/delivery_method_sets/:id" do
    it "updates the set name" do
      patch admin_listings_delivery_method_set_path(delivery_method_set),
        params: { listings_delivery_method_set: { name: "Updated Name" } }

      expect(delivery_method_set.reload.name).to eq("Updated Name")
    end

    it "responds with a redirect for HTML" do
      patch admin_listings_delivery_method_set_path(delivery_method_set),
        params: { listings_delivery_method_set: { name: "Updated Name" } }

      expect(response).to redirect_to(admin_listings_delivery_method_sets_path)
    end
  end

  describe "DELETE /admin/listings/delivery_method_sets/:id" do
    it "destroys the set" do
      expect {
        delete admin_listings_delivery_method_set_path(delivery_method_set)
      }.to change(Listings::DeliveryMethodSet, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_listings_delivery_method_set_path(delivery_method_set)

      expect(response).to redirect_to(admin_listings_delivery_method_sets_path)
      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_listings_delivery_method_set_path(delivery_method_set)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
