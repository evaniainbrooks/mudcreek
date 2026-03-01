require "rails_helper"

RSpec.describe "Admin::Listings::Attachments", type: :request do
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
  let!(:attachment) do
    listing.images.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    listing.images.first
  end

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "DELETE /admin/listings/:listing_hashid/attachments/:id" do
    it "redirects to the listing edit page" do
      delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: attachment.id)

      expect(response).to redirect_to(edit_admin_listing_path(listing))
    end

    it "sets a notice flash including the filename" do
      delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: attachment.id)

      expect(flash[:notice]).to include("photo.jpg")
    end

    it "schedules the attachment for purge" do
      expect(attachment).to receive(:purge_later)
      allow(ActiveStorage::Attachment).to receive(:find_by!).and_return(attachment)

      delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: attachment.id)
    end

    context "with a non-existent attachment id" do
      it "returns 404" do
        delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: attachment.id)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_listings", description: "No listing access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_listing_attachment_path(listing_hashid: listing.hashid, id: attachment.id)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
