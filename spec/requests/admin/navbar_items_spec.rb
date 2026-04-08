require "rails_helper"

RSpec.describe "Admin::NavbarItems", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "nav_manager", description: "Manage navbar").tap do |r|
      r.permissions.create!(resource: "NavbarItem", action: "index")
      r.permissions.create!(resource: "NavbarItem", action: "create")
      r.permissions.create!(resource: "NavbarItem", action: "update")
      r.permissions.create!(resource: "NavbarItem", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:navbar_item) { create(:navbar_item, title: "Schedule", path: "/schedule", position: 1) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/navbar_items" do
    it "returns 200 and lists the item" do
      get admin_navbar_items_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Schedule")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_navbar_items_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_nav", description: "No navbar access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_navbar_items_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/navbar_items/new" do
    it "returns 200" do
      get new_admin_navbar_item_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/navbar_items/:id/edit" do
    it "returns 200" do
      get edit_admin_navbar_item_path(navbar_item)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/navbar_items" do
    let(:valid_params) { { navbar_item: { title: "About", path: "/about", icon: "bi-info-circle", position: 2 } } }

    context "with valid params" do
      it "creates a new navbar item" do
        expect {
          post admin_navbar_items_path, params: valid_params
        }.to change(NavbarItem, :count).by(1)
      end

      it "redirects to the index" do
        post admin_navbar_items_path, params: valid_params

        expect(response).to redirect_to(admin_navbar_items_path)
      end
    end

    context "with a missing title" do
      it "does not create an item" do
        expect {
          post admin_navbar_items_path, params: { navbar_item: { title: "", path: "/about", position: 2 } }
        }.not_to change(NavbarItem, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_navbar_items_path, params: { navbar_item: { title: "", path: "/about", position: 2 } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a missing path" do
      it "does not create an item" do
        expect {
          post admin_navbar_items_path, params: { navbar_item: { title: "About", path: "", position: 2 } }
        }.not_to change(NavbarItem, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_navbar_items_path, params: { navbar_item: { title: "About", path: "", position: 2 } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_navbar_items_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_nav", description: "Read-only navbar access").tap do |r|
          r.permissions.create!(resource: "NavbarItem", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_navbar_items_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/navbar_items/:id" do
    context "with valid params" do
      it "updates the item" do
        patch admin_navbar_item_path(navbar_item), params: { navbar_item: { title: "Full Schedule" } }

        expect(navbar_item.reload.title).to eq("Full Schedule")
      end

      it "redirects to the index" do
        patch admin_navbar_item_path(navbar_item), params: { navbar_item: { title: "Full Schedule" } }

        expect(response).to redirect_to(admin_navbar_items_path)
      end
    end

    context "with invalid params" do
      it "re-renders edit with unprocessable_content status" do
        patch admin_navbar_item_path(navbar_item), params: { navbar_item: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_nav", description: "Read-only navbar access").tap do |r|
          r.permissions.create!(resource: "NavbarItem", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_navbar_item_path(navbar_item), params: { navbar_item: { title: "X" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/navbar_items/:id" do
    it "destroys the item" do
      expect {
        delete admin_navbar_item_path(navbar_item)
      }.to change(NavbarItem, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_navbar_item_path(navbar_item)

      expect(response).to redirect_to(admin_navbar_items_path)
      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_navbar_item_path(navbar_item)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_nav", description: "Read-only navbar access").tap do |r|
          r.permissions.create!(resource: "NavbarItem", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_navbar_item_path(navbar_item)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
