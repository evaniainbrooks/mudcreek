require "rails_helper"

RSpec.describe "Home", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  describe "GET /" do
    context "when no homepage page is configured" do
      it "redirects permanently to /listings" do
        get root_path

        expect(response).to redirect_to(listings_path)
        expect(response).to have_http_status(:moved_permanently)
      end
    end

    context "when a published page is configured as the homepage" do
      let!(:page) { create(:page, :published, title: "Welcome") }

      before { Current.tenant.update!(homepage_page: page) }

      it "returns 200" do
        get root_path

        expect(response).to have_http_status(:ok)
      end

      it "renders the page content" do
        get root_path

        expect(response.body).to include("Welcome")
      end

      it "does not redirect" do
        get root_path

        expect(response).not_to be_redirect
      end
    end

    context "when the configured homepage page is unpublished" do
      let!(:page) { create(:page, title: "Draft") }

      before { Current.tenant.update!(homepage_page: page) }

      it "redirects permanently to /listings" do
        get root_path

        expect(response).to redirect_to(listings_path)
        expect(response).to have_http_status(:moved_permanently)
      end
    end
  end
end
