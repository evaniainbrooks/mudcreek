require "rails_helper"

RSpec.describe "Admin::EmailAliases", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "email_alias_manager", description: "Manage email aliases").tap do |r|
      r.permissions.create!(resource: "EmailAlias", action: "index")
      r.permissions.create!(resource: "EmailAlias", action: "create")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/email_aliases" do
    context "when no check has been run" do
      before { Rails.cache.delete("improvmx_domain_check_#{Current.tenant.id}") }

      it "returns 200" do
        get admin_email_aliases_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the tenant custom domain" do
        get admin_email_aliases_path

        expect(response.body).to include("example.com")
      end

      it "shows the verify button" do
        get admin_email_aliases_path

        expect(response.body).to include("Verify DNS")
      end
    end

    context "when a cached result exists" do
      before do
        allow(Rails.cache).to receive(:read)
          .with("improvmx_domain_check_#{Current.tenant.id}")
          .and_return({ success: true, records: [], errors: [] })
      end

      it "shows the valid status" do
        get admin_email_aliases_path

        expect(response.body).to include("DNS configuration is valid")
      end
    end

    context "when the tenant has no custom domain" do
      before { Current.tenant.update!(custom_domain: nil) }

      it "shows the missing domain warning" do
        get admin_email_aliases_path

        expect(response.body).to include("No custom domain configured")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_email_aliases_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_email_alias", description: "No email alias access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_email_aliases_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/email_aliases/verify" do
    it "enqueues a CheckImprovmxDomainJob" do
      expect {
        post admin_verify_email_aliases_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to have_enqueued_job(CheckImprovmxDomainJob).with(Current.tenant.id)
    end

    it "returns a turbo stream response with the checking spinner" do
      post admin_verify_email_aliases_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("improvmx-status")
      expect(response.body).to include("spinner-border")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_verify_email_aliases_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_email_alias", description: "Read-only email alias access").tap do |r|
          r.permissions.create!(resource: "EmailAlias", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_verify_email_aliases_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
