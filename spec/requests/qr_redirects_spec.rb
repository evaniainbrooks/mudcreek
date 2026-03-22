require "rails_helper"

RSpec.describe "QrRedirects", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:qr_code) { create(:qr_code, slug: "my-code", destination_url: "https://destination.example.com") }

  describe "GET /q/:slug" do
    context "with an active code" do
      it "redirects to the destination URL" do
        get qr_redirect_path("my-code")

        expect(response).to redirect_to("https://destination.example.com")
        expect(response).to have_http_status(:found)
      end

      it "increments scan_count" do
        expect {
          get qr_redirect_path("my-code")
        }.to change { qr_code.reload.scan_count }.by(1)
      end

      it "creates a QrScan record" do
        expect {
          get qr_redirect_path("my-code")
        }.to change(QrScan, :count).by(1)
      end

      it "records last_scanned_at" do
        get qr_redirect_path("my-code")

        expect(qr_code.reload.last_scanned_at).to be_within(5.seconds).of(Time.current)
      end

      it "captures the user agent on the scan record" do
        get qr_redirect_path("my-code"), headers: { "User-Agent" => "TestBrowser/1.0" }

        expect(QrScan.last.user_agent).to eq("TestBrowser/1.0")
      end
    end

    context "with a code that has a future expiry" do
      let!(:qr_code) { create(:qr_code, :with_expiry, slug: "expiring-code", destination_url: "https://destination.example.com") }

      it "treats the code as live and redirects" do
        get qr_redirect_path("expiring-code")

        expect(response).to redirect_to("https://destination.example.com")
      end

      it "increments scan_count" do
        expect {
          get qr_redirect_path("expiring-code")
        }.to change { qr_code.reload.scan_count }.by(1)
      end
    end

    context "with an inactive code" do
      let!(:qr_code) { create(:qr_code, :inactive, slug: "inactive-code", destination_url: "https://destination.example.com") }

      it "redirects to root when no fallback URL is set" do
        get qr_redirect_path("inactive-code")

        expect(response).to redirect_to(root_path)
        expect(response).to have_http_status(:found)
      end

      it "redirects to the fallback URL when set" do
        qr_code.update!(inactive_url: "https://fallback.example.com")

        get qr_redirect_path("inactive-code")

        expect(response).to redirect_to("https://fallback.example.com")
      end

      it "does not increment scan_count" do
        expect {
          get qr_redirect_path("inactive-code")
        }.not_to change { qr_code.reload.scan_count }
      end

      it "does not create a QrScan record" do
        expect {
          get qr_redirect_path("inactive-code")
        }.not_to change(QrScan, :count)
      end
    end

    context "with an expired code" do
      let!(:qr_code) { create(:qr_code, :expired, slug: "expired-code", destination_url: "https://destination.example.com") }

      it "redirects to root" do
        get qr_redirect_path("expired-code")

        expect(response).to redirect_to(root_path)
        expect(response).to have_http_status(:found)
      end

      it "redirects to the fallback URL when set" do
        qr_code.update!(inactive_url: "https://fallback.example.com")

        get qr_redirect_path("expired-code")

        expect(response).to redirect_to("https://fallback.example.com")
      end

      it "does not increment scan_count" do
        expect {
          get qr_redirect_path("expired-code")
        }.not_to change { qr_code.reload.scan_count }
      end

      it "does not create a QrScan record" do
        expect {
          get qr_redirect_path("expired-code")
        }.not_to change(QrScan, :count)
      end
    end

    context "with an unknown slug" do
      it "redirects to root without raising a 404" do
        get qr_redirect_path("nonexistent")

        expect(response).to redirect_to(root_path)
        expect(response).to have_http_status(:found)
      end
    end
  end
end
