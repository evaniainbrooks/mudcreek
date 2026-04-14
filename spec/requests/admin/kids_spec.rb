require "rails_helper"

RSpec.describe "Admin::Kids", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "kids_manager", description: "Manage kids").tap do |r|
      r.permissions.create!(resource: "Kid", action: "index")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:kid) { create(:kid) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/kids" do
    it "returns 200" do
      get admin_kids_path

      expect(response).to have_http_status(:ok)
    end

    it "lists the kid's name" do
      get admin_kids_path

      expect(response.body).to include(kid.name)
    end

    context "with a ransack search filter" do
      let!(:other_kid) { create(:kid, name: "ZZZUnique") }

      it "filters results by name" do
        get admin_kids_path, params: { q: { name_cont: "ZZZUnique" } }

        expect(response.body).to include("ZZZUnique")
        expect(response.body).not_to include(kid.name)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_kids_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_kids", description: "No kid access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_kids_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
