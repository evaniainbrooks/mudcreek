require "rails_helper"

RSpec.describe "Admin::Listings::PropertySets::Properties", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "property_manager", description: "Manage properties").tap do |r|
      r.permissions.create!(resource: "Listings::Property", action: "create")
      r.permissions.create!(resource: "Listings::Property", action: "update")
      r.permissions.create!(resource: "Listings::Property", action: "destroy")
    end
  end

  let(:user)         { create(:user, role: role) }
  let(:property_set) { create(:listings_property_set) }
  let(:property)     { create(:listings_property, property_set: property_set) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "POST /admin/listings/property_sets/:property_set_id/properties" do
    it "creates a new property on the property set" do
      expect {
        post admin_listings_property_set_properties_path(property_set),
          params: { listings_property: { name: "Author", value: "Ernest Hemingway" } }
      }.to change { property_set.properties.count }.by(1)
    end

    it "redirects with a notice on success" do
      post admin_listings_property_set_properties_path(property_set),
        params: { listings_property: { name: "Author", value: "Ernest Hemingway" } }

      expect(response).to redirect_to(admin_listings_property_set_path(property_set))
      expect(flash[:notice]).to include("Author")
    end

    context "with a blank name" do
      it "does not create a property" do
        expect {
          post admin_listings_property_set_properties_path(property_set),
            params: { listings_property: { name: "", value: "Ernest Hemingway" } }
        }.not_to change { Listings::Property.count }
      end

      it "returns 422" do
        post admin_listings_property_set_properties_path(property_set),
          params: { listings_property: { name: "", value: "Ernest Hemingway" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a blank value" do
      it "does not create a property" do
        expect {
          post admin_listings_property_set_properties_path(property_set),
            params: { listings_property: { name: "Author", value: "" } }
        }.not_to change { Listings::Property.count }
      end

      it "returns 422" do
        post admin_listings_property_set_properties_path(property_set),
          params: { listings_property: { name: "Author", value: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listings_property_set_properties_path(property_set),
          params: { listings_property: { name: "Author", value: "Ernest Hemingway" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_create", description: "No create") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listings_property_set_properties_path(property_set),
            params: { listings_property: { name: "Author", value: "Ernest Hemingway" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/listings/property_sets/:property_set_id/properties/:id" do
    it "updates the property name" do
      patch admin_listings_property_set_property_path(property_set, property),
        params: { listings_property: { name: "Updated Name" } }

      expect(property.reload.name).to eq("Updated Name")
    end

    it "updates the property value" do
      patch admin_listings_property_set_property_path(property_set, property),
        params: { listings_property: { value: "Updated Value" } }

      expect(property.reload.value).to eq("Updated Value")
    end

    context "HTML format" do
      it "redirects to the property set show page" do
        patch admin_listings_property_set_property_path(property_set, property),
          params: { listings_property: { name: "Updated Name" } }

        expect(response).to redirect_to(admin_listings_property_set_path(property_set))
      end
    end

    context "Turbo Stream format" do
      it "responds with turbo_stream content type" do
        patch admin_listings_property_set_property_path(property_set, property),
          params: { listings_property: { name: "Updated Name" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to start_with("text/vnd.turbo-stream.html")
      end

      it "renders replace stream actions for the name and value cells" do
        patch admin_listings_property_set_property_path(property_set, property),
          params: { listings_property: { name: "Updated Name" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.body).to include('action="replace"')
        expect(response.body).to include("listings_property_#{property.id}_name")
        expect(response.body).to include("listings_property_#{property.id}_value")
      end
    end

    context "with a blank name" do
      it "does not update the property" do
        original_name = property.name
        patch admin_listings_property_set_property_path(property_set, property),
          params: { listings_property: { name: "" } }

        expect(property.reload.name).to eq(original_name)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_listings_property_set_property_path(property_set, property),
          params: { listings_property: { name: "Updated Name" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_update", description: "No update") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_listings_property_set_property_path(property_set, property),
            params: { listings_property: { name: "Updated Name" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/listings/property_sets/:property_set_id/properties/:id" do
    it "destroys the property" do
      property
      expect {
        delete admin_listings_property_set_property_path(property_set, property)
      }.to change { Listings::Property.count }.by(-1)
    end

    it "redirects with a notice" do
      name = property.name
      delete admin_listings_property_set_property_path(property_set, property)

      expect(response).to redirect_to(admin_listings_property_set_path(property_set))
      expect(flash[:notice]).to include(name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listings_property_set_property_path(property_set, property)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) { Role.create!(name: "no_destroy", description: "No destroy") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listings_property_set_property_path(property_set, property)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
