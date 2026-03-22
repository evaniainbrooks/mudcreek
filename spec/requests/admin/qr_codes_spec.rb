require "rails_helper"

RSpec.describe "Admin::QrCodes", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "qr_manager", description: "Manage QR codes").tap do |r|
      r.permissions.create!(resource: "QrCode", action: "index")
      r.permissions.create!(resource: "QrCode", action: "show")
      r.permissions.create!(resource: "QrCode", action: "create")
      r.permissions.create!(resource: "QrCode", action: "update")
      r.permissions.create!(resource: "QrCode", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:qr_code) { create(:qr_code, name: "Test Code", slug: "test-code", destination_url: "https://example.com") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/qr_codes" do
    it "returns 200 and lists the QR code" do
      get admin_qr_codes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Code")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_qr_codes_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_qr", description: "No QR access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_qr_codes_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/qr_codes/:slug" do
    it "returns 200 and shows stats" do
      get admin_qr_code_path(qr_code)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Code")
    end

    it "displays the owner name" do
      qr_code.update!(owner: user)

      get admin_qr_code_path(qr_code)

      expect(response.body).to include(user.name)
    end

    context "with recent scans" do
      before { qr_code.qr_scans.create!(ip_address: "1.2.3.4", user_agent: "ScanBot/1.0") }

      it "displays the scan log" do
        get admin_qr_code_path(qr_code)

        expect(response.body).to include("1.2.3.4")
        expect(response.body).to include("ScanBot/1.0")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_qr_code_path(qr_code)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) do
        Role.create!(name: "index_only_qr", description: "Index-only QR access").tap do |r|
          r.permissions.create!(resource: "QrCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_qr_code_path(qr_code) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/qr_codes/:slug/edit" do
    it "returns 200" do
      get edit_admin_qr_code_path(qr_code)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/qr_codes/:slug/qr_image.svg" do
    it "returns 200 with svg content type" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("image/svg+xml")
    end

    it "serves inline by default" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg)

      expect(response.headers["Content-Disposition"]).to include("inline")
    end

    it "serves as attachment when download param is set" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg, download: "1")

      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes the slug in the filename" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg, download: "1")

      expect(response.headers["Content-Disposition"]).to include("test-code")
    end

    %w[sm md lg].each do |size|
      it "accepts size=#{size}" do
        get qr_image_admin_qr_code_path(qr_code, format: :svg, size: size)

        expect(response).to have_http_status(:ok)
      end
    end

    it "falls back to md for an unknown size" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg, size: "xxl")

      expect(response).to have_http_status(:ok)
    end

    %w[standard blue indigo purple pink red orange green teal].each do |style|
      it "accepts style=#{style}" do
        get qr_image_admin_qr_code_path(qr_code, format: :svg, style: style)

        expect(response).to have_http_status(:ok)
      end
    end

    it "falls back to standard for an unknown style" do
      get qr_image_admin_qr_code_path(qr_code, format: :svg, style: "neon")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/qr_codes/:slug/qr_image.png" do
    it "returns 200 with png content type" do
      get qr_image_admin_qr_code_path(qr_code, format: :png)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("image/png")
    end

    it "serves as attachment" do
      get qr_image_admin_qr_code_path(qr_code, format: :png)

      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes the slug in the filename" do
      get qr_image_admin_qr_code_path(qr_code, format: :png)

      expect(response.headers["Content-Disposition"]).to include("test-code")
    end

    %w[sm md lg].each do |size|
      it "accepts size=#{size}" do
        get qr_image_admin_qr_code_path(qr_code, format: :png, size: size)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/qr_codes/new" do
    it "returns 200" do
      get new_admin_qr_code_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/qr_codes" do
    let(:valid_params) do
      { qr_code: { name: "New Code", slug: "new-code", destination_url: "https://newdest.example.com" } }
    end

    context "with valid params" do
      it "creates a new QR code" do
        expect {
          post admin_qr_codes_path, params: valid_params
        }.to change(QrCode, :count).by(1)
      end

      it "redirects to the index" do
        post admin_qr_codes_path, params: valid_params

        expect(response).to redirect_to(admin_qr_codes_path)
      end

      it "derives slug from name when slug is blank" do
        post admin_qr_codes_path, params: { qr_code: { name: "Auto Slug Code", slug: "", destination_url: "https://example.com" } }

        expect(QrCode.find_by(name: "Auto Slug Code").slug).to eq("auto-slug-code")
      end

      it "sets the owner to the current user" do
        post admin_qr_codes_path, params: valid_params

        expect(QrCode.find_by(name: "New Code").owner).to eq(user)
      end
    end

    context "with a duplicate slug" do
      it "does not create a QR code" do
        expect {
          post admin_qr_codes_path, params: { qr_code: { name: "Dup", slug: "test-code", destination_url: "https://example.com" } }
        }.not_to change(QrCode, :count)
      end

      it "re-renders new with unprocessable_content status" do
        post admin_qr_codes_path, params: { qr_code: { name: "Dup", slug: "test-code", destination_url: "https://example.com" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_qr_codes_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_qr", description: "Read-only QR access").tap do |r|
          r.permissions.create!(resource: "QrCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_qr_codes_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/qr_codes/:slug" do
    context "with valid params" do
      it "updates the QR code" do
        patch admin_qr_code_path(qr_code), params: { qr_code: { active: false } }

        expect(qr_code.reload.active).to be(false)
      end

      it "redirects to the index" do
        patch admin_qr_code_path(qr_code), params: { qr_code: { name: "Updated Name" } }

        expect(response).to redirect_to(admin_qr_codes_path)
      end

      it "does not allow the owner to be changed" do
        qr_code.update!(owner: user)
        other_user = create(:user)

        patch admin_qr_code_path(qr_code), params: { qr_code: { owner_id: other_user.id } }

        expect(qr_code.reload.owner).to eq(user)
      end
    end

    context "with invalid params" do
      it "re-renders edit with unprocessable_content status" do
        patch admin_qr_code_path(qr_code), params: { qr_code: { destination_url: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_qr", description: "Read-only QR access").tap do |r|
          r.permissions.create!(resource: "QrCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_qr_code_path(qr_code), params: { qr_code: { name: "Updated" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/qr_codes/:slug" do
    it "destroys the QR code" do
      expect {
        delete admin_qr_code_path(qr_code)
      }.to change(QrCode, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_qr_code_path(qr_code)

      expect(response).to redirect_to(admin_qr_codes_path)
      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_qr_code_path(qr_code)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_qr", description: "Read-only QR access").tap do |r|
          r.permissions.create!(resource: "QrCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_qr_code_path(qr_code)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
