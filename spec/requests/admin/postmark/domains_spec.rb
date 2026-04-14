require "rails_helper"

RSpec.describe "Admin::Postmark::Domains", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "postmark_domain_manager", description: "Manage Postmark domains").tap do |r|
      r.permissions.create!(resource: "Postmark::Domain", action: "create")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/postmark/domains" do
    it "enqueues a ProvisionPostmarkDomainJob for the current tenant" do
      expect {
        post admin_postmark_domains_path
      }.to have_enqueued_job(ProvisionPostmarkDomainJob).with(Current.tenant.id)
    end

    it "redirects to the sender signatures page with a notice" do
      post admin_postmark_domains_path

      expect(response).to redirect_to(admin_sender_signatures_path)
      expect(flash[:notice]).to include("enqueued")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_postmark_domains_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_postmark_domain", description: "No Postmark domain access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_postmark_domains_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/postmark/domains/verify" do
    before do
      Postmark::Domain.create!(tenant: Current.tenant, external_id: 8139, api_response: {})
    end

    it "enqueues a VerifyPostmarkDomainJob for the current tenant" do
      expect {
        post verify_admin_postmark_domains_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to have_enqueued_job(VerifyPostmarkDomainJob).with(Current.tenant.id)
    end

    it "returns a turbo stream response with the checking spinner" do
      post verify_admin_postmark_domains_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("postmark-domain-status")
      expect(response.body).to include("spinner-border")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post verify_admin_postmark_domains_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_postmark_verify", description: "No Postmark verify access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post verify_admin_postmark_domains_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
