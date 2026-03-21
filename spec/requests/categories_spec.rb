require "rails_helper"

RSpec.describe "Categories", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:category) { create(:listings_category) }

  describe "GET /categories" do
    it "returns 200" do
      get categories_path

      expect(response).to have_http_status(:ok)
    end

    it "displays category names" do
      get categories_path

      expect(response.body).to include(category.name)
    end

    it "is accessible without authentication" do
      get categories_path

      expect(response).to have_http_status(:ok)
    end
  end
end
