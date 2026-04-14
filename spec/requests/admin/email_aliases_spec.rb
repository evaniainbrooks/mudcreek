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
      r.permissions.create!(resource: "EmailAlias", action: "destroy")
    end
  end

  let(:email_alias) do
    EmailAlias.create!(
      tenant: Current.tenant,
      external_id: 1,
      alias: "hello",
      forward: "user@example.com"
    )
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/email_aliases" do
    context "when no Improvmx::Domain record exists" do
      it "returns 200" do
        get admin_email_aliases_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the tenant custom domain" do
        get admin_email_aliases_path

        expect(response.body).to include("example.com")
      end

      it "shows the register domain button" do
        get admin_email_aliases_path

        expect(response.body).to include("Register Domain")
      end
    end

    context "when an Improvmx::Domain record exists with status unchecked" do
      before { Improvmx::Domain.create!(tenant: Current.tenant, api_response: {}) }

      it "shows the verify button" do
        get admin_email_aliases_path

        expect(response.body).to include("Verify DNS")
      end
    end

    context "when the domain status is verified" do
      before { Improvmx::Domain.create!(tenant: Current.tenant, api_response: {}, status: :verified, check_data: { "success" => true, "errors" => [] }) }

      it "shows the valid status" do
        get admin_email_aliases_path

        expect(response.body).to include("DNS configuration is valid")
      end
    end

    context "when the domain status is failed" do
      before { Improvmx::Domain.create!(tenant: Current.tenant, api_response: {}, status: :failed, check_data: { "success" => false, "errors" => ["MX record missing"] }) }

      it "shows the DNS issues message" do
        get admin_email_aliases_path

        expect(response.body).to include("DNS configuration has issues")
        expect(response.body).to include("MX record missing")
      end
    end

    context "when aliases exist" do
      before do
        Improvmx::Domain.create!(tenant: Current.tenant, api_response: {})
        email_alias
      end

      it "renders each alias row without error" do
        get admin_email_aliases_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("hello")
        expect(response.body).to include("user@example.com")
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

  describe "POST /admin/email_aliases" do
    let(:valid_params) { { email_alias: { alias: "hello", forward: "user@example.com" } } }

    it "enqueues a CreateEmailAliasJob" do
      expect {
        post admin_email_aliases_path, params: valid_params
      }.to have_enqueued_job(CreateEmailAliasJob).with(Current.tenant.id, "hello", "user@example.com")
    end

    it "redirects to the index with a processing notice" do
      post admin_email_aliases_path, params: valid_params

      expect(response).to redirect_to(admin_email_aliases_path)
      expect(flash[:notice]).to include("being processed")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_email_aliases_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_email_alias", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "EmailAlias", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_email_aliases_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/email_aliases/:id" do
    it "enqueues a DeleteEmailAliasJob" do
      expect {
        delete admin_email_alias_path(email_alias)
      }.to have_enqueued_job(DeleteEmailAliasJob).with(email_alias.id)
    end

    it "redirects to the index with a processing notice" do
      delete admin_email_alias_path(email_alias)

      expect(response).to redirect_to(admin_email_aliases_path)
      expect(flash[:notice]).to include("being processed")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_email_alias_path(email_alias)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "no_destroy_email_alias", description: "No destroy access").tap do |r|
          r.permissions.create!(resource: "EmailAlias", action: "index")
          r.permissions.create!(resource: "EmailAlias", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_email_alias_path(email_alias)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

end
