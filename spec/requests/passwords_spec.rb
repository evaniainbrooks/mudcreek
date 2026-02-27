require "rails_helper"

RSpec.describe "Passwords", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", default: true)
  end

  let(:user) { create(:user) }

  describe "GET /passwords/new" do
    it "returns 200" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    context "when the email matches a user" do
      it "redirects to the sign-in page with a notice" do
        post passwords_path, params: { email_address: user.email_address }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to match(/Password reset instructions sent/)
      end

      it "enqueues a password reset email" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)
      end
    end

    context "when no user has that email" do
      it "redirects to the sign-in page with the same notice" do
        post passwords_path, params: { email_address: "nobody@example.com" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to match(/Password reset instructions sent/)
      end

      it "does not enqueue any mail" do
        expect {
          post passwords_path, params: { email_address: "nobody@example.com" }
        }.not_to have_enqueued_mail
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    context "with a valid token" do
      it "returns 200" do
        get edit_password_path(user.password_reset_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to the new password page with an alert" do
        get edit_password_path("invalid-token")

        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to match(/invalid or has expired/)
      end
    end
  end

  describe "PATCH /passwords/:token" do
    context "with a valid token and matching passwords" do
      it "redirects to the sign-in page with a notice" do
        token = user.password_reset_token
        patch password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to eq("Password has been reset.")
      end

      it "updates the user's password" do
        token = user.password_reset_token
        patch password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }

        expect(user.reload.authenticate("newpassword")).to be_truthy
      end

      it "destroys all existing sessions" do
        user.sessions.create!
        token = user.password_reset_token
        patch password_path(token), params: { password: "newpassword", password_confirmation: "newpassword" }

        expect(user.sessions.count).to eq(0)
      end
    end

    context "with a valid token but mismatched passwords" do
      it "redirects back to the edit page with an alert" do
        token = user.password_reset_token
        patch password_path(token), params: { password: "newpassword", password_confirmation: "different" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to eq("Passwords did not match.")
      end

      it "does not change the user's password" do
        token = user.password_reset_token
        patch password_path(token), params: { password: "newpassword", password_confirmation: "different" }

        expect(user.reload.authenticate("password")).to be_truthy
      end
    end

    context "with an invalid token" do
      it "redirects to the new password page with an alert" do
        patch password_path("invalid-token"),
          params: { password: "newpassword", password_confirmation: "newpassword" }

        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to match(/invalid or has expired/)
      end
    end
  end
end
