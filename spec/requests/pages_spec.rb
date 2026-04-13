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

    context "when the page has children" do
      let!(:child_one) { create(:page, :published, title: "History", slug: "history", parent: page, position: 1) }
      let!(:child_two) { create(:page, :published, title: "Mission", slug: "mission", parent: page, position: 2) }
      let!(:unpublished_child) { create(:page, title: "Draft Child", slug: "draft-child", parent: page) }

      it "renders the first child tab as active by default" do
        get page_path(slug: "about-us")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("History")
        expect(response.body).to include("Mission")
        expect(response.body).not_to include("Draft Child")
      end

      it "renders the selected child when tab param is provided" do
        get page_path(slug: "about-us", tab: "mission")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Mission")
      end

      it "falls back to the first child when tab param does not match" do
        get page_path(slug: "about-us", tab: "nonexistent")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("History")
      end

      it "does not render tabs when the page has no published children" do
        child_one.update!(published: false)
        child_two.update!(published: false)

        get page_path(slug: "about-us")

        expect(response.body).not_to include('nav-tabs')
      end
    end
  end
end
