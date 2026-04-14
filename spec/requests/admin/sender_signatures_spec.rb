require "rails_helper"

RSpec.describe "Admin::SenderSignatures", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "sender_sig_manager", description: "Manage sender signatures").tap do |r|
      r.permissions.create!(resource: "SenderSignature", action: "index")
      r.permissions.create!(resource: "SenderSignature", action: "create")
      r.permissions.create!(resource: "SenderSignature", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/sender_signatures" do
    it "returns 200" do
      get admin_sender_signatures_path

      expect(response).to have_http_status(:ok)
    end

    context "with existing signatures" do
      let!(:sig) do
        SenderSignature.create!(
          tenant: Current.tenant,
          external_id: 1,
          name: "Example Co.",
          email_address: "hello@example.com",
          confirmed: true,
          dkim_verified: false,
          spf_verified: false,
          return_path_domain_verified: false
        )
      end

      it "renders each signature row" do
        get admin_sender_signatures_path

        expect(response.body).to include("hello@example.com")
        expect(response.body).to include("Example Co.")
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
      let(:role) { Role.create!(name: "no_sender_sig", description: "No sender sig access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_sender_signatures_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/sender_signatures" do
    let(:valid_params) { { sender_signature: { name: "Example Co.", email_address: "hello@example.com" } } }

    it "enqueues a CreateSenderSignatureJob" do
      expect {
        post admin_sender_signatures_path, params: valid_params
      }.to have_enqueued_job(CreateSenderSignatureJob).with(Current.tenant.id, "hello@example.com", "Example Co.")
    end

    it "redirects to the index with a notice" do
      post admin_sender_signatures_path, params: valid_params

      expect(response).to redirect_to(admin_sender_signatures_path)
      expect(flash[:notice]).to include("being processed")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_sender_signatures_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_sender_sig", description: "Read only").tap do |r|
          r.permissions.create!(resource: "SenderSignature", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_sender_signatures_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/sender_signatures/:id" do
    let!(:sig) do
      SenderSignature.create!(
        tenant: Current.tenant,
        external_id: 1,
        name: "Example Co.",
        email_address: "hello@example.com",
        confirmed: false,
        dkim_verified: false,
        spf_verified: false,
        return_path_domain_verified: false
      )
    end

    it "enqueues a DeleteSenderSignatureJob" do
      expect {
        delete admin_sender_signature_path(sig)
      }.to have_enqueued_job(DeleteSenderSignatureJob).with(sig.id)
    end

    it "redirects to the index with a notice" do
      delete admin_sender_signature_path(sig)

      expect(response).to redirect_to(admin_sender_signatures_path)
      expect(flash[:notice]).to include("being processed")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_sender_signature_path(sig)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "no_destroy_sender_sig", description: "No destroy").tap do |r|
          r.permissions.create!(resource: "SenderSignature", action: "index")
          r.permissions.create!(resource: "SenderSignature", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_sender_signature_path(sig)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
