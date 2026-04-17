require "rails_helper"

RSpec.describe "Podium", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  describe "GET /podium" do
    it "returns 200" do
      get podium_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the Podium heading" do
      get podium_path

      expect(response.body).to include("Podium")
    end

    it "is accessible without signing in" do
      get podium_path

      expect(response).to have_http_status(:ok)
    end

    it "is accessible when signed in" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get podium_path

      expect(response).to have_http_status(:ok)
    end
  end
end
