require "rails_helper"

RSpec.describe "Admin::Cloudflare::TurnstileWidgets", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, custom_domain: "example.com")
  end

  let(:role) do
    Role.create!(name: "turnstile_provisioner", description: "Provision Turnstile widgets").tap do |r|
      r.permissions.create!(resource: "Cloudflare::TurnstileWidget", action: "create")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/cloudflare/turnstile_widgets" do
    it "enqueues a ProvisionCloudflareTurnstileJob for the current tenant" do
      expect {
        post admin_cloudflare_turnstile_widgets_path
      }.to have_enqueued_job(ProvisionCloudflareTurnstileJob).with(Current.tenant.id)
    end

    it "redirects to the turnstiles page with a notice" do
      post admin_cloudflare_turnstile_widgets_path

      expect(response).to redirect_to(admin_turnstiles_path)
      expect(flash[:notice]).to include("enqueued")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_cloudflare_turnstile_widgets_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_turnstile_create", description: "No Turnstile create access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_cloudflare_turnstile_widgets_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
