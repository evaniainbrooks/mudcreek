require "rails_helper"

RSpec.describe "Admin::Listings::Categories", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "category_manager", description: "Manage categories").tap do |r|
      r.permissions.create!(resource: "Listings::Category", action: "index")
      r.permissions.create!(resource: "Listings::Category", action: "create")
      r.permissions.create!(resource: "Listings::Category", action: "update")
      r.permissions.create!(resource: "Listings::Category", action: "destroy")
    end
  end

  let(:user)     { create(:user, role: role) }
  let(:category) { create(:listings_category) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/listings/categories" do
    it "returns 200" do
      get admin_listings_categories_path

      expect(response).to have_http_status(:ok)
    end

    it "displays existing categories" do
      category
      get admin_listings_categories_path

      expect(response.body).to include(category.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_listings_categories_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_categories", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_listings_categories_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/listings/categories" do
    it "creates a new category" do
      expect {
        post admin_listings_categories_path, params: { listings_category: { name: "Furniture" } }
      }.to change { Listings::Category.count }.by(1)
    end

    it "redirects with a notice on success" do
      post admin_listings_categories_path, params: { listings_category: { name: "Furniture" } }

      expect(response).to redirect_to(admin_listings_categories_path)
      expect(flash[:notice]).to include("Furniture")
    end

    context "with a blank name" do
      it "does not create a category" do
        expect {
          post admin_listings_categories_path, params: { listings_category: { name: "" } }
        }.not_to change { Listings::Category.count }
      end

      it "returns 422" do
        post admin_listings_categories_path, params: { listings_category: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a duplicate name" do
      before { category }

      it "does not create a duplicate" do
        expect {
          post admin_listings_categories_path, params: { listings_category: { name: category.name } }
        }.not_to change { Listings::Category.count }
      end

      it "returns 422" do
        post admin_listings_categories_path, params: { listings_category: { name: category.name } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_listings_categories_path, params: { listings_category: { name: "Furniture" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_create", description: "No create") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listings_categories_path, params: { listings_category: { name: "Furniture" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/listings/categories/:hashid" do
    it "updates the category name" do
      patch admin_listings_category_path(category), params: { listings_category: { name: "Updated Name" } }

      expect(category.reload.name).to eq("Updated Name")
    end

    it "redirects to the categories index" do
      patch admin_listings_category_path(category), params: { listings_category: { name: "Updated Name" } }

      expect(response).to redirect_to(admin_listings_categories_path)
    end

    context "with a blank name" do
      it "does not update the category" do
        original_name = category.name
        patch admin_listings_category_path(category), params: { listings_category: { name: "" } }

        expect(category.reload.name).to eq(original_name)
      end

      it "renders the edit form" do
        patch admin_listings_category_path(category), params: { listings_category: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("can&#39;t be blank")
      end
    end

    context "with an unknown hashid" do
      it "returns 404" do
        patch "/admin/listings/categories/nonexistent", params: { listings_category: { name: "x" } }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_listings_category_path(category), params: { listings_category: { name: "Updated Name" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Listings::Category", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_listings_category_path(category), params: { listings_category: { name: "Updated Name" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/listings/categories/:hashid" do
    it "destroys the category" do
      category
      expect {
        delete admin_listings_category_path(category)
      }.to change { Listings::Category.count }.by(-1)
    end

    it "redirects with a notice" do
      name = category.name
      delete admin_listings_category_path(category)

      expect(response).to redirect_to(admin_listings_categories_path)
      expect(flash[:notice]).to include(name)
    end

    context "with an unknown hashid" do
      it "returns 404" do
        delete "/admin/listings/categories/nonexistent"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listings_category_path(category)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Listings::Category", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listings_category_path(category)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
