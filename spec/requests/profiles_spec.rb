require "rails_helper"

RSpec.describe "Profiles", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /profile/edit — orders tab" do
    context "when the user has no orders" do
      it "returns 200" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the empty state message" do
        get edit_profile_path

        expect(response.body).to include("You haven&#39;t placed any orders yet.")
      end
    end

    context "when the user has orders" do
      let!(:order) { create(:order, user: user) }

      it "returns 200" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
      end

      it "displays the order number" do
        get edit_profile_path

        expect(response.body).to include(order.number)
      end

      it "displays the order total" do
        get edit_profile_path

        expect(response.body).to include("11.50")
      end
    end

    context "when the user has multiple orders" do
      let!(:older_order) { create(:order, user: user, created_at: 2.days.ago) }
      let!(:newer_order) { create(:order, user: user, created_at: 1.day.ago) }

      it "shows the newer order before the older one" do
        get edit_profile_path

        expect(response.body.index(newer_order.number)).to be < response.body.index(older_order.number)
      end
    end

    context "when another user has orders" do
      let(:other_user) { create(:user) }
      let!(:other_order) { create(:order, user: other_user) }

      it "does not display the other user's order" do
        get edit_profile_path

        expect(response.body).not_to include(other_order.number)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get edit_profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
