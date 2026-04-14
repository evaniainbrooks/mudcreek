require "rails_helper"

RSpec.describe "Admin::SenderSignatures", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "sender_domain_manager", description: "Manage sender domain").tap do |r|
      r.permissions.create!(resource: "Postmark::Domain", action: "index")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/sender_signatures" do
    it "returns 200" do
      get admin_sender_signatures_path

      expect(response).to have_http_status(:ok)
    end

    context "when no Postmark::Domain record exists" do
      it "shows the register domain button" do
        get admin_sender_signatures_path

        expect(response.body).to include("Register Domain")
      end
    end

    context "when a Postmark::Domain record exists with status unchecked" do
      before do
        Postmark::Domain.create!(
          tenant: Current.tenant,
          external_id: 8139,
          api_response: { "name" => "example.com", "dkim_host" => "pm._domainkey.example.com", "dkim_text_value" => "v=DKIM1;p=abc", "return_path_domain" => "pm-bounces.example.com" }
        )
      end

      it "shows the DNS records" do
        get admin_sender_signatures_path

        expect(response.body).to include("pm._domainkey.example.com")
        expect(response.body).to include("pm-bounces.example.com")
      end

      it "shows the verify button" do
        get admin_sender_signatures_path

        expect(response.body).to include("Verify DNS")
      end
    end

    context "when the domain status is verified" do
      before do
        Postmark::Domain.create!(
          tenant: Current.tenant,
          external_id: 8139,
          status: :verified,
          api_response: { "name" => "example.com", "dkim_verified" => true }
        )
      end

      it "shows the verified status" do
        get admin_sender_signatures_path

        expect(response.body).to include("DNS configuration is valid")
      end
    end

    context "when the domain status is failed" do
      before do
        Postmark::Domain.create!(
          tenant: Current.tenant,
          external_id: 8139,
          status: :failed,
          api_response: { "name" => "example.com", "dkim_verified" => false }
        )
      end

      it "shows the failed status" do
        get admin_sender_signatures_path

        expect(response.body).to include("DNS configuration has issues")
      end
    end

    context "when the tenant has no custom domain" do
      before { Current.tenant.update!(custom_domain: nil) }

      it "shows the missing domain warning" do
        get admin_sender_signatures_path

        expect(response.body).to include("No custom domain configured")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_sender_signatures_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_sender_domain", description: "No sender domain access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_sender_signatures_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
