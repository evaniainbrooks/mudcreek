require "rails_helper"

RSpec.describe "Admin::Listings::PropertySets", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "property_set_manager", description: "Manage property sets").tap do |r|
      r.permissions.create!(resource: "Listings::PropertySet", action: "index")
      r.permissions.create!(resource: "Listings::PropertySet", action: "show")
      r.permissions.create!(resource: "Listings::PropertySet", action: "create")
      r.permissions.create!(resource: "Listings::PropertySet", action: "update")
      r.permissions.create!(resource: "Listings::PropertySet", action: "destroy")
      r.permissions.create!(resource: "Listings::PropertySet", action: "reorder")
    end
  end

  let(:user)         { create(:user, role: role) }
  let(:property_set) { create(:listings_property_set) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/listings/property_sets" do
    it "returns 200" do
      get admin_listings_property_sets_path

      expect(response).to have_http_status(:ok)
    end

    it "lists property sets" do
      property_set  # force creation before request
      get admin_listings_property_sets_path

      expect(response.body).to include(property_set.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_listings_property_sets_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_listings_property_sets_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/listings/property_sets/:id" do
    it "returns 200" do
      get admin_listings_property_set_path(property_set)

      expect(response).to have_http_status(:ok)
    end

    it "displays the property set name" do
      get admin_listings_property_set_path(property_set)

      expect(response.body).to include(property_set.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_listings_property_set_path(property_set)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          get admin_listings_property_set_path(property_set)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/listings/property_sets/:id/listing_fields" do
    let!(:property) { create(:listings_property, property_set: property_set, name: "Color", value: "Red") }

    it "returns JSON" do
      get listing_fields_admin_listings_property_set_path(property_set)

      expect(response.content_type).to start_with("application/json")
    end

    it "includes property name and value" do
      get listing_fields_admin_listings_property_set_path(property_set)

      json = JSON.parse(response.body)
      expect(json).to include(include("name" => "Color", "value" => "Red"))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get listing_fields_admin_listings_property_set_path(property_set)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/listings/property_sets/reorder" do
    let!(:property) { create(:listings_property, property_set: property_set) }

    it "returns 200" do
      patch reorder_admin_listings_property_sets_path, params: { id: property.id, position: 1 }

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch reorder_admin_listings_property_sets_path, params: { id: property.id, position: 1 }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/listings/property_sets" do
    it "creates a new property set" do
      expect {
        post admin_listings_property_sets_path, params: { listings_property_set: { name: "Furniture" } }
      }.to change { Listings::PropertySet.count }.by(1)
    end

    it "redirects with a notice on success" do
      post admin_listings_property_sets_path, params: { listings_property_set: { name: "Furniture" } }

      expect(response).to redirect_to(admin_listings_property_sets_path)
      expect(flash[:notice]).to include("Furniture")
    end

    context "with a blank name" do
      it "does not create a property set" do
        expect {
          post admin_listings_property_sets_path, params: { listings_property_set: { name: "" } }
        }.not_to change { Listings::PropertySet.count }
      end

      it "returns 422" do
        post admin_listings_property_sets_path, params: { listings_property_set: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listings_property_sets_path, params: { listings_property_set: { name: "Furniture" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_create", description: "No create") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listings_property_sets_path, params: { listings_property_set: { name: "Furniture" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/listings/property_sets/:id" do
    it "updates the property set name" do
      patch admin_listings_property_set_path(property_set), params: { listings_property_set: { name: "Updated Name" } }

      expect(property_set.reload.name).to eq("Updated Name")
    end

    context "HTML format" do
      it "redirects to the property sets index" do
        patch admin_listings_property_set_path(property_set), params: { listings_property_set: { name: "Updated Name" } }

        expect(response).to redirect_to(admin_listings_property_sets_path)
      end
    end

    context "Turbo Stream format" do
      it "responds with turbo_stream content type" do
        patch admin_listings_property_set_path(property_set),
          params: { listings_property_set: { name: "Updated Name" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to start_with("text/vnd.turbo-stream.html")
      end

      it "renders a replace stream action for the name cell" do
        patch admin_listings_property_set_path(property_set),
          params: { listings_property_set: { name: "Updated Name" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('action="replace"')
        expect(response.body).to include("listings_property_set_#{property_set.id}_name")
      end
    end

    context "with a blank name" do
      it "does not update the property set" do
        original_name = property_set.name
        patch admin_listings_property_set_path(property_set), params: { listings_property_set: { name: "" } }

        expect(property_set.reload.name).to eq(original_name)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_listings_property_set_path(property_set), params: { listings_property_set: { name: "Updated Name" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Listings::PropertySet", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_listings_property_set_path(property_set), params: { listings_property_set: { name: "Updated Name" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/listings/property_sets/:id" do
    it "destroys the property set" do
      property_set
      expect {
        delete admin_listings_property_set_path(property_set)
      }.to change { Listings::PropertySet.count }.by(-1)
    end

    it "also destroys associated properties" do
      create(:listings_property, property_set: property_set)
      expect {
        delete admin_listings_property_set_path(property_set)
      }.to change { Listings::Property.count }.by(-1)
    end

    it "redirects with a notice" do
      name = property_set.name
      delete admin_listings_property_set_path(property_set)

      expect(response).to redirect_to(admin_listings_property_sets_path)
      expect(flash[:notice]).to include(name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listings_property_set_path(property_set)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Listings::PropertySet", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listings_property_set_path(property_set)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
