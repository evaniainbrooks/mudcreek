require "rails_helper"

RSpec.describe "Admin::Improvmx::Domains", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "improvmx_domain_manager", description: "Manage ImprovMX domains").tap do |r|
      r.permissions.create!(resource: "Improvmx::Domain", action: "create")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/improvmx/domains" do
    it "enqueues a ProvisionImprovmxDomainJob for the current tenant" do
      expect {
        post admin_improvmx_domains_path
      }.to have_enqueued_job(ProvisionImprovmxDomainJob).with(Current.tenant.id)
    end

    it "redirects to the email aliases page with a notice" do
      post admin_improvmx_domains_path

      expect(response).to redirect_to(admin_email_aliases_path)
      expect(flash[:notice]).to include("enqueued")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_improvmx_domains_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_improvmx_domain", description: "No ImprovMX domain access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_improvmx_domains_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/improvmx/domains/verify" do
    before { Improvmx::Domain.create!(tenant: Current.tenant, api_response: {}) }

    it "enqueues a CheckImprovmxDomainJob" do
      expect {
        post verify_admin_improvmx_domains_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to have_enqueued_job(CheckImprovmxDomainJob).with(Current.tenant.id)
    end

    it "returns a turbo stream response with the checking spinner" do
      post verify_admin_improvmx_domains_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("improvmx-status")
      expect(response.body).to include("spinner-border")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post verify_admin_improvmx_domains_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_improvmx_verify", description: "No ImprovMX verify access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post verify_admin_improvmx_domains_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
