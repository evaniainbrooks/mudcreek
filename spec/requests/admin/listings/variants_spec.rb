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
  let(:variant)  { Listings::Variant.create!(listing: listing, tenant: Current.tenant) }

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

  # ------------------------------------------------------------------ #
  describe "GET /admin/listings/:listing_hashid/variants/:id/edit" do
    it "returns 200" do
      get edit_admin_listing_variant_path(listing, variant)

      expect(response).to have_http_status(:ok)
    end

    it "builds an in-memory gallery when the variant has none" do
      get edit_admin_listing_variant_path(listing, variant)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get edit_admin_listing_variant_path(listing, variant)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/listings/:listing_hashid/variants/:id" do
    context "with valid params" do
      it "creates a gallery and redirects to variant edit" do
        patch admin_listing_variant_path(listing, variant),
              params: { listings_variant: { gallery_attributes: { name: "Variant Gallery" } } }

        expect(response).to redirect_to(edit_admin_listing_variant_path(listing, variant))
      end

      it "sets the gallery name" do
        patch admin_listing_variant_path(listing, variant),
              params: { listings_variant: { gallery_attributes: { name: "My Gallery" } } }

        expect(variant.reload.gallery.name).to eq("My Gallery")
      end

      it "sets a flash notice" do
        patch admin_listing_variant_path(listing, variant),
              params: { listings_variant: { gallery_attributes: { name: "Gallery" } } }

        expect(flash[:notice]).to eq("Gallery updated.")
      end
    end

    context "with invalid params" do
      before { allow_any_instance_of(Listings::Variant).to receive(:update).and_return(false) }

      it "renders edit with 422" do
        patch admin_listing_variant_path(listing, variant),
              params: { listings_variant: { gallery_attributes: { name: "Gallery" } } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_listing_variant_path(listing, variant),
              params: { listings_variant: { gallery_attributes: { name: "Gallery" } } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
