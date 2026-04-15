require "rails_helper"

RSpec.describe "Admin::Turnstiles", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "turnstile_manager", description: "Manage Turnstile").tap do |r|
      r.permissions.create!(resource: "Cloudflare::TurnstileWidget", action: "index")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/turnstiles" do
    context "when Cloudflare credentials are not configured" do
      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:cloudflare, :api_token).and_return(nil)
      end

      it "shows the missing credentials error" do
        get admin_turnstiles_path

        expect(response.body).to include("Cloudflare credentials are not configured")
      end
    end

    context "when Cloudflare credentials are present" do
      before do
        allow(Rails.application.credentials).to receive(:dig).and_call_original
        allow(Rails.application.credentials).to receive(:dig).with(:cloudflare, :api_token).and_return("test_token")
        allow(Rails.application.credentials).to receive(:dig).with(:cloudflare, :account_id).and_return("test_account_id")
      end

      it "returns 200" do
        get admin_turnstiles_path

        expect(response).to have_http_status(:ok)
      end

      context "when no widget is attached" do
        it "shows the provision button" do
          get admin_turnstiles_path

          expect(response.body).to include("Provision Widget")
        end
      end

      context "when a widget is attached" do
        before do
          Cloudflare::TurnstileWidget.create!(
            tenant: Current.tenant,
            external_id: "0x4AAAAAAAxyz",
            api_response: {
              "sitekey" => "0x4AAAAAAAxyz",
              "secret" => "0x4AAAAAAAsecret",
              "name" => "Test Turnstile",
              "domains" => [ "example.com" ],
              "mode" => "managed"
            }
          )
        end

        it "shows the sitekey" do
          get admin_turnstiles_path

          expect(response.body).to include("0x4AAAAAAAxyz")
        end

        it "shows the mode" do
          get admin_turnstiles_path

          expect(response.body).to include("Managed")
        end

        it "shows the registered domain" do
          get admin_turnstiles_path

          expect(response.body).to include("example.com")
        end
      end

      context "when the tenant has no custom domain" do
        before { Current.tenant.update!(custom_domain: nil) }

        it "shows the missing domain warning" do
          get admin_turnstiles_path

          expect(response.body).to include("No custom domain configured")
        end
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_turnstiles_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_turnstile", description: "No Turnstile access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_turnstiles_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
