require "rails_helper"

RSpec.describe "Admin::Lots::ListingPlaceholder", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "lot_manager", description: "Manage lots").tap do |r|
      r.permissions.create!(resource: "Lot", action: "update")
    end
  end

  let(:owner) { create(:user) }
  let(:user)  { create(:user, role: role) }
  let!(:lot)  { create(:lot, owner: owner) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "DELETE /admin/lots/:lot_id/listing_placeholder" do
    it "redirects to the lots index" do
      delete admin_lot_listing_placeholder_path(lot)

      expect(response).to redirect_to(admin_lots_path)
    end

    it "sets a notice flash including the lot name" do
      delete admin_lot_listing_placeholder_path(lot)

      expect(flash[:notice]).to include(lot.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_lot_listing_placeholder_path(lot)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_lots", description: "No lot access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_lot_listing_placeholder_path(lot)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
