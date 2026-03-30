require "rails_helper"

RSpec.describe "Profiles::Verifications", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true, features: { user_verifications: true })
  end

  let(:user) { create(:user) }
  let(:document) { fixture_file_upload(Rails.root.join("spec/fixtures/images/cat.jpg"), "image/jpeg") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /profile/verification" do
    context "when the user has no verification" do
      it "returns 200" do
        get profile_verification_path

        expect(response).to have_http_status(:ok)
      end

      it "renders the upload form" do
        get profile_verification_path

        expect(response.body).to include("Upload document")
      end
    end

    context "when the user has a verification under review" do
      before { create(:users_verification, user: user) }

      it "shows the under review status" do
        get profile_verification_path

        expect(response.body).to include("under review")
      end

      it "shows the replace document button" do
        get profile_verification_path

        expect(response.body).to include("Replace document")
      end
    end

    context "when the user has a validated verification" do
      before { create(:users_verification, :validated, user: user) }

      it "shows the verified status" do
        get profile_verification_path

        expect(response.body).to include("identity has been verified")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get profile_verification_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /profile/verification" do
    context "with a valid document" do
      it "redirects to the verification page" do
        patch profile_verification_path, params: { verification: { verification_document: document } }

        expect(response).to redirect_to(profile_verification_path)
      end

      it "sets a success notice" do
        patch profile_verification_path, params: { verification: { verification_document: document } }
        follow_redirect!

        expect(response.body).to include("Verification document uploaded.")
      end

      it "attaches the document to the user's verification" do
        patch profile_verification_path, params: { verification: { verification_document: document } }

        expect(user.reload.verification.verification_document).to be_attached
      end
    end

    context "when the user already has a verification" do
      before { create(:users_verification, user: user) }

      it "redirects to the verification page" do
        patch profile_verification_path, params: { verification: { verification_document: document } }

        expect(response).to redirect_to(profile_verification_path)
      end

      it "does not create a duplicate verification record" do
        expect {
          patch profile_verification_path, params: { verification: { verification_document: document } }
        }.not_to change { Users::Verification.count }
      end
    end

    context "without a document" do
      it "creates a verification record and redirects" do
        patch profile_verification_path, params: { verification: {} }

        expect(response).to redirect_to(profile_verification_path)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch profile_verification_path, params: { verification: { verification_document: document } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
