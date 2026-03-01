require "rails_helper"

RSpec.describe "Subdivisions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /subdivisions" do
    context "with a country that has subdivisions" do
      it "returns 200" do
        get subdivisions_path, params: { country_code: "CA" }

        expect(response).to have_http_status(:ok)
      end

      it "returns JSON" do
        get subdivisions_path, params: { country_code: "CA" }

        expect(response.content_type).to include("application/json")
      end

      it "returns subdivision names for Canada" do
        get subdivisions_path, params: { country_code: "CA" }

        expect(response.parsed_body).to include("Alberta", "British Columbia", "Ontario")
      end

      it "returns subdivision names sorted alphabetically" do
        get subdivisions_path, params: { country_code: "CA" }

        names = response.parsed_body
        expect(names).to eq(names.sort)
      end

      it "returns state names for the US" do
        get subdivisions_path, params: { country_code: "US" }

        expect(response.parsed_body).to include("California", "New York", "Texas")
      end
    end

    context "with an unknown country code" do
      it "returns 200" do
        get subdivisions_path, params: { country_code: "ZZ" }

        expect(response).to have_http_status(:ok)
      end

      it "returns an empty array" do
        get subdivisions_path, params: { country_code: "ZZ" }

        expect(response.parsed_body).to eq([])
      end
    end

    context "without a country_code param" do
      it "returns an empty array" do
        get subdivisions_path

        expect(response.parsed_body).to eq([])
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get subdivisions_path, params: { country_code: "CA" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
