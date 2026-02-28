require "rails_helper"

RSpec.describe "Admin::Listings reorder", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:role) do
    Role.create!(name: "can_reorder", description: "Reorder listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "reorder")
    end
  end

  let(:user) { create(:user, role: role) }

  let!(:listing_a) { create(:listing, owner: user) }
  let!(:listing_b) { create(:listing, owner: user) }
  let!(:listing_c) { create(:listing, owner: user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "PATCH /admin/listings/reorder" do
    it "returns 200 OK" do
      patch reorder_admin_listings_path, params: { id: listing_c.id, position: 1 }

      expect(response).to have_http_status(:ok)
    end

    it "moves the listing to the given position" do
      patch reorder_admin_listings_path, params: { id: listing_c.id, position: 1 }

      expect(listing_c.reload.position).to eq(1)
    end

    it "shifts other listings down accordingly" do
      patch reorder_admin_listings_path, params: { id: listing_c.id, position: 1 }

      expect(listing_a.reload.position).to eq(2)
      expect(listing_b.reload.position).to eq(3)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch reorder_admin_listings_path, params: { id: listing_a.id, position: 2 }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the reorder permission" do
      let(:role) { Role.create!(name: "no_reorder", description: "No reorder access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch reorder_admin_listings_path, params: { id: listing_a.id, position: 2 }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
