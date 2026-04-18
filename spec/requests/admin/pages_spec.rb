require "rails_helper"

RSpec.describe "Admin::Pages", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "page_manager", description: "Manage pages").tap do |r|
      r.permissions.create!(resource: "Page", action: "index")
      r.permissions.create!(resource: "Page", action: "create")
      r.permissions.create!(resource: "Page", action: "update")
      r.permissions.create!(resource: "Page", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:page) { create(:page, title: "About Us", slug: "about-us") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/pages" do
    it "returns 200 and lists the page" do
      get admin_pages_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("About Us")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_pages_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_pages", description: "No page access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_pages_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/pages/new" do
    it "returns 200" do
      get new_admin_page_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/pages/:id/edit" do
    it "returns 200" do
      get edit_admin_page_path(page)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/pages" do
    context "with valid params" do
      let(:valid_params) { { page: { title: "FAQ", slug: "faq", published: true, show_in_nav: false, position: 1 } } }

      it "creates a new page" do
        expect {
          post admin_pages_path, params: valid_params
        }.to change(Page, :count).by(1)
      end

      it "redirects to the index" do
        post admin_pages_path, params: valid_params

        expect(response).to redirect_to(admin_pages_path)
      end

      it "derives slug from title when slug is blank" do
        post admin_pages_path, params: { page: { title: "Terms of Service", slug: "" } }

        expect(Page.find_by(title: "Terms of Service").slug).to eq("terms-of-service")
      end
    end

    context "with a missing title" do
      it "does not create a page" do
        expect {
          post admin_pages_path, params: { page: { title: "", slug: "no-title" } }
        }.not_to change(Page, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_pages_path, params: { page: { title: "", slug: "no-title" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid slug" do
      it "does not create a page" do
        expect {
          post admin_pages_path, params: { page: { title: "Bad Slug", slug: "Bad Slug!" } }
        }.not_to change(Page, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_pages_path, params: { page: { title: "Bad Slug", slug: "Bad Slug!" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a duplicate slug" do
      it "does not create a page" do
        expect {
          post admin_pages_path, params: { page: { title: "Duplicate", slug: "about-us" } }
        }.not_to change(Page, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_pages_path, params: { page: { title: "FAQ", slug: "faq" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_pages", description: "Read-only page access").tap do |r|
          r.permissions.create!(resource: "Page", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_pages_path, params: { page: { title: "FAQ", slug: "faq" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/pages/:id" do
    context "with valid params" do
      it "updates the page" do
        patch admin_page_path(page), params: { page: { title: "About the Company" } }

        expect(page.reload.title).to eq("About the Company")
      end

      it "redirects to the index" do
        patch admin_page_path(page), params: { page: { title: "About the Company" } }

        expect(response).to redirect_to(admin_pages_path)
      end
    end

    context "with invalid params" do
      it "re-renders edit with unprocessable_content status" do
        patch admin_page_path(page), params: { page: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_pages", description: "Read-only page access").tap do |r|
          r.permissions.create!(resource: "Page", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_page_path(page), params: { page: { title: "New Title" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/pages/:id" do
    it "destroys the page" do
      expect {
        delete admin_page_path(page)
      }.to change(Page, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_page_path(page)

      expect(response).to redirect_to(admin_pages_path)
      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_page_path(page)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_pages", description: "Read-only page access").tap do |r|
          r.permissions.create!(resource: "Page", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_page_path(page)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
