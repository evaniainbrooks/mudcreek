require "rails_helper"

RSpec.describe "QrCodes", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:qr_code) { create(:qr_code, slug: "test-qr") }

  describe "GET /qr/:slug/image" do
    context "with a live QR code" do
      it "returns SVG content" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("image/svg+xml")
      end

      it "returns PNG content" do
        get qr_code_image_path(slug: qr_code.slug, format: :png)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("image/png")
      end

      it "serves SVG inline by default" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg)

        expect(response.headers["Content-Disposition"]).to include("inline")
      end

      it "serves SVG as attachment when download param is present" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg, download: "1")

        expect(response.headers["Content-Disposition"]).to include("attachment")
      end

      it "includes the slug in the filename" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg)

        expect(response.headers["Content-Disposition"]).to include("test-qr")
      end
    end

    context "with an inactive QR code" do
      let!(:qr_code) { create(:qr_code, :inactive, slug: "inactive-qr") }

      it "returns 404" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an expired QR code" do
      let!(:qr_code) { create(:qr_code, :expired, slug: "expired-qr") }

      it "returns 404" do
        get qr_code_image_path(slug: qr_code.slug, format: :svg)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a non-existent slug" do
      it "returns 404" do
        get qr_code_image_path(slug: "no-such-slug", format: :svg)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
