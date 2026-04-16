require "rails_helper"

RSpec.describe "Admin::Galleries", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "gallery_manager", description: "Manage galleries").tap do |r|
      r.permissions.create!(resource: "Gallery", action: "index")
      r.permissions.create!(resource: "Gallery", action: "create")
      r.permissions.create!(resource: "Gallery", action: "update")
      r.permissions.create!(resource: "Gallery", action: "destroy")
    end
  end

  let(:user)    { create(:user, role: role) }
  let!(:gallery) { create(:gallery, name: "Wildflower Gallery") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/galleries" do
    it "returns 200 and lists the gallery" do
      get admin_galleries_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Wildflower Gallery")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_galleries_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_galleries", description: "No gallery access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_galleries_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/galleries/new" do
    it "returns 200" do
      get new_admin_gallery_path

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get new_admin_gallery_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/galleries/:id/edit" do
    it "returns 200" do
      get edit_admin_gallery_path(gallery)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get edit_admin_gallery_path(gallery)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/galleries" do
    context "with a valid name" do
      it "creates the gallery" do
        expect {
          post admin_galleries_path, params: { gallery: { name: "Spring Collection" } }
        }.to change(Gallery, :count).by(1)
      end

      it "redirects to the galleries index" do
        post admin_galleries_path, params: { gallery: { name: "Spring Collection" } }

        expect(response).to redirect_to(admin_galleries_path)
      end

      it "does not assign a listing" do
        post admin_galleries_path, params: { gallery: { name: "Spring Collection" } }

        expect(Gallery.last.listing).to be_nil
      end
    end

    context "when listing_id is supplied" do
      let(:listing) { create(:listing) }

      it "ignores the listing_id" do
        post admin_galleries_path, params: { gallery: { name: "Sneaky", listing_id: listing.id } }

        expect(Gallery.last.listing).to be_nil
      end
    end

    context "with a blank name" do
      it "does not create a gallery" do
        expect {
          post admin_galleries_path, params: { gallery: { name: "" } }
        }.not_to change(Gallery, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_galleries_path, params: { gallery: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_galleries_path, params: { gallery: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_galleries", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Gallery", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_galleries_path, params: { gallery: { name: "Blocked" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/galleries/:id" do
    context "with a valid name" do
      it "updates the gallery name" do
        patch admin_gallery_path(gallery), params: { gallery: { name: "Renamed Gallery" } }

        expect(gallery.reload.name).to eq("Renamed Gallery")
      end

      it "redirects to the galleries index" do
        patch admin_gallery_path(gallery), params: { gallery: { name: "Renamed Gallery" } }

        expect(response).to redirect_to(admin_galleries_path)
      end
    end

    context "when listing_id is supplied" do
      let(:listing) { create(:listing) }

      it "does not change the listing assignment" do
        patch admin_gallery_path(gallery), params: { gallery: { name: "Same", listing_id: listing.id } }

        expect(gallery.reload.listing).to be_nil
      end
    end

    context "with a blank name" do
      it "re-renders edit with unprocessable_content" do
        patch admin_gallery_path(gallery), params: { gallery: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_gallery_path(gallery), params: { gallery: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_galleries", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Gallery", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_gallery_path(gallery), params: { gallery: { name: "Blocked" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/galleries/:id" do
    it "destroys the gallery" do
      expect {
        delete admin_gallery_path(gallery)
      }.to change(Gallery, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_gallery_path(gallery)

      expect(response).to redirect_to(admin_galleries_path)
      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_gallery_path(gallery)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_galleries", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Gallery", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_gallery_path(gallery)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
