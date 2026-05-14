require "rails_helper"

RSpec.describe "Admin::Galleries::Attachments", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "gallery_editor", description: "Edit galleries").tap do |r|
      r.permissions.create!(resource: "Gallery", action: "update")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:gallery) { create(:gallery) }
  let!(:attachment) do
    gallery.photos.attach(
      io: StringIO.new("fake image data"),
      filename: "photo.jpg",
      content_type: "image/jpeg"
    )
    gallery.photos.first
  end

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "DELETE /admin/galleries/:gallery_id/attachments/:id" do
    it "redirects to the gallery edit page" do
      delete admin_gallery_attachment_path(gallery_id: gallery.id, id: attachment.id)

      expect(response).to redirect_to(edit_admin_gallery_path(gallery))
    end

    it "sets a notice flash including the filename" do
      delete admin_gallery_attachment_path(gallery_id: gallery.id, id: attachment.id)

      expect(flash[:notice]).to include("photo.jpg")
    end

    it "schedules the attachment for purge" do
      expect(attachment).to receive(:purge_later)
      allow(ActiveStorage::Attachment).to receive(:find_by!).and_return(attachment)

      delete admin_gallery_attachment_path(gallery_id: gallery.id, id: attachment.id)
    end

    context "with a non-existent attachment id" do
      it "returns 404" do
        delete admin_gallery_attachment_path(gallery_id: gallery.id, id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_gallery_attachment_path(gallery_id: gallery.id, id: attachment.id)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) { Role.create!(name: "no_galleries", description: "No gallery access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_gallery_attachment_path(gallery_id: gallery.id, id: attachment.id)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
