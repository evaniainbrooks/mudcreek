require "rails_helper"

RSpec.describe "Admin::Listings::Variants", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "listing_updater", description: "Update listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "update")
    end
  end

  let(:user)     { create(:user, role: role) }
  let!(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/listings/:listing_hashid/variants" do
    before { allow(Listings::VariantGenerator).to receive(:call) }

    it "calls VariantGenerator and redirects to edit" do
      post admin_listing_variants_path(listing)

      expect(Listings::VariantGenerator).to have_received(:call).with(listing: listing)
      expect(response).to redirect_to(edit_admin_listing_path(listing))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_listing_variants_path(listing)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks update permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listing_variants_path(listing)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
