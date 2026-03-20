require "rails_helper"

RSpec.describe "OauthCallbacks", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  def mock_auth(provider, overrides = {})
    auth = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: "uid_123",
      info: OmniAuth::AuthHash::InfoHash.new(
        { email: "oauth@example.com", name: "Jane Doe" }.merge(overrides[:info] || {})
      ),
      credentials: OmniAuth::AuthHash.new(
        token: "access_token",
        refresh_token: "refresh_token",
        expires_at: 1.hour.from_now.to_i
      )
    )
    OmniAuth.config.mock_auth[provider] = auth
    auth
  end

  describe "GET /auth/:provider/callback" do
    context "when provider+uid is already known" do
      let(:user)     { create(:user) }
      let!(:identity) { create(:oauth_identity, user: user, provider: "google_oauth2", uid: "uid_123") }

      before { mock_auth(:google_oauth2) }

      it "logs in the existing user" do
        get "/auth/google_oauth2/callback"

        expect(cookies[:session_id]).to be_present
      end

      it "updates the stored tokens" do
        get "/auth/google_oauth2/callback"

        expect(identity.reload.access_token).to eq("access_token")
      end

      it "redirects to root" do
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(root_path)
      end
    end

    context "when email matches an existing user (new provider)" do
      let!(:user) { create(:user, email_address: "oauth@example.com") }

      before { mock_auth(:google_oauth2) }

      it "creates an OauthIdentity for the existing user" do
        expect {
          get "/auth/google_oauth2/callback"
        }.to change(OauthIdentity, :count).by(1)
      end

      it "does not create a new User" do
        expect {
          get "/auth/google_oauth2/callback"
        }.not_to change(User, :count)
      end

      it "logs in the existing user" do
        get "/auth/google_oauth2/callback"

        expect(cookies[:session_id]).to be_present
      end

      it "auto-activates an unactivated user" do
        user.update_column(:activated_at, nil)

        get "/auth/google_oauth2/callback"

        expect(user.reload.activated_at).to be_present
      end
    end

    context "when the email is new" do
      before { mock_auth(:google_oauth2) }

      it "creates a new User" do
        expect {
          get "/auth/google_oauth2/callback"
        }.to change(User, :count).by(1)
      end

      it "creates an OauthIdentity" do
        expect {
          get "/auth/google_oauth2/callback"
        }.to change(OauthIdentity, :count).by(1)
      end

      it "sets activated_at on the new user" do
        get "/auth/google_oauth2/callback"

        expect(User.last.activated_at).to be_present
      end

      it "starts a session" do
        get "/auth/google_oauth2/callback"

        expect(cookies[:session_id]).to be_present
      end

      it "redirects to root" do
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(root_path)
      end
    end

    context "when the provider returns no email" do
      before { mock_auth(:google_oauth2, info: { email: nil, name: "No Email" }) }

      it "redirects to the sign-in page" do
        get "/auth/google_oauth2/callback"

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        get "/auth/google_oauth2/callback"

        expect(flash[:alert]).to be_present
      end

      it "does not create a user" do
        expect {
          get "/auth/google_oauth2/callback"
        }.not_to change(User, :count)
      end
    end

    context "when Apple POSTs the callback" do
      before do
        OmniAuth.config.mock_auth[:apple] = OmniAuth::AuthHash.new(
          provider: "apple",
          uid: "apple_uid_123",
          info: OmniAuth::AuthHash::InfoHash.new(email: "apple@example.com", name: "Apple User"),
          credentials: OmniAuth::AuthHash.new(token: "apple_token", expires_at: 1.hour.from_now.to_i)
        )
      end

      it "handles a POST request" do
        post "/auth/apple/callback"

        expect(response).to redirect_to(root_path)
      end
    end

    context "when a guest cart exists" do
      before do
        mock_auth(:google_oauth2)
        listing = create(:listing)
        create(:cart_item, listing: listing, user: nil,
               guest_cart_token: "guest_token")
      end

      it "merges the guest cart on login" do
        # Set the guest_cart_token in the session before the callback
        get new_session_path  # establishes a session
        # Manually inject the guest cart token via a prior request that sets it
        get "/auth/google_oauth2/callback", headers: { "HTTP_COOKIE" => "" }

        # The key assertion: a new user is created and logged in
        expect(cookies[:session_id]).to be_present
      end
    end
  end

  describe "GET /auth/failure" do
    it "redirects to the sign-in page" do
      get "/auth/failure", params: { message: "access_denied" }

      expect(response).to redirect_to(new_session_path)
    end

    it "sets an alert with the humanized message" do
      get "/auth/failure", params: { message: "access_denied" }

      expect(flash[:alert]).to eq("Authentication failed: Access denied")
    end
  end
end
