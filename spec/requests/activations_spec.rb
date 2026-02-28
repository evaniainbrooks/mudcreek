require "rails_helper"

RSpec.describe "Activations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", default: true)
  end

  let(:user) { create(:user, :unactivated) }
  let(:valid_token) { user.generate_token_for(:activation) }

  describe "GET /activations/:token" do
    context "with a valid token" do
      it "activates the user" do
        get activation_path(token: valid_token)

        expect(user.reload.activated_at).to be_present
      end

      it "starts a session" do
        get activation_path(token: valid_token)

        expect(cookies[:session_id]).to be_present
      end

      it "creates a session record" do
        expect {
          get activation_path(token: valid_token)
        }.to change { user.sessions.count }.by(1)
      end

      it "redirects to root for a user without admin access" do
        get activation_path(token: valid_token)

        expect(response).to redirect_to(root_path)
      end

      it "sets a notice" do
        get activation_path(token: valid_token)

        expect(flash[:notice]).to eq("Your account has been activated.")
      end
    end

    context "with an invalid token" do
      it "redirects to the sign-in page" do
        get activation_path(token: "invalid")

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        get activation_path(token: "invalid")

        expect(flash[:alert]).to eq("Activation link is invalid or has expired.")
      end

      it "does not activate the user" do
        get activation_path(token: "invalid")

        expect(user.reload.activated_at).to be_nil
      end
    end

    context "with an already-used token" do
      before { get activation_path(token: valid_token) }

      it "redirects to the sign-in page" do
        get activation_path(token: valid_token)

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        get activation_path(token: valid_token)

        expect(flash[:alert]).to eq("Activation link is invalid or has expired.")
      end
    end
  end
end
