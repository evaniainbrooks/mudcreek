require "rails_helper"

RSpec.describe "Pages", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let!(:page) { create(:page, :published, title: "About Us", slug: "about-us") }

  describe "GET /pages/:slug" do
    it "returns 200" do
      get page_path(slug: "about-us")

      expect(response).to have_http_status(:ok)
    end

    it "displays the page content" do
      get page_path(slug: "about-us")

      expect(response.body).to include("About Us")
    end

    context "when the page is unpublished" do
      let!(:page) { create(:page, title: "Draft", slug: "draft") }

      it "returns 404" do
        get page_path(slug: "draft")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the slug does not exist" do
      it "returns 404" do
        get page_path(slug: "nonexistent")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "still returns 200 (public access)" do
        get page_path(slug: "about-us")

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
