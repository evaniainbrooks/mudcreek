require "rails_helper"

RSpec.describe "Admin::Listings::Variants::Attachments", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "listing_editor", description: "Edit listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "update")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:listing) { create(:listing) }
  let(:variant) { Listings::Variant.create!(listing: listing, tenant: Current.tenant) }
  let(:gallery) { Gallery.create!(name: "Variant Gallery", variant: variant, tenant: Current.tenant) }
  let!(:attachment) do
    gallery.photos.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    gallery.photos.first
  end

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "DELETE /admin/listings/:listing_hashid/variants/:variant_id/attachments/:id" do
    it "redirects to the variant edit page" do
      delete admin_listing_variant_attachment_path(
        listing_hashid: listing.hashid,
        variant_id: variant.id,
        id: attachment.id
      )

      expect(response).to redirect_to(edit_admin_listing_variant_path(listing, variant))
    end

    it "sets a notice flash including the filename" do
      delete admin_listing_variant_attachment_path(
        listing_hashid: listing.hashid,
        variant_id: variant.id,
        id: attachment.id
      )

      expect(flash[:notice]).to include("photo.jpg")
    end

    it "schedules the attachment for purge" do
      expect(attachment).to receive(:purge_later)
      allow(ActiveStorage::Attachment).to receive(:find_by!).and_return(attachment)

      delete admin_listing_variant_attachment_path(
        listing_hashid: listing.hashid,
        variant_id: variant.id,
        id: attachment.id
      )
    end

    context "with a non-existent attachment id" do
      it "returns 404" do
        delete admin_listing_variant_attachment_path(
          listing_hashid: listing.hashid,
          variant_id: variant.id,
          id: 0
        )

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listing_variant_attachment_path(
          listing_hashid: listing.hashid,
          variant_id: variant.id,
          id: attachment.id
        )

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_listings", description: "No listing access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listing_variant_attachment_path(
            listing_hashid: listing.hashid,
            variant_id: variant.id,
            id: attachment.id
          )
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
