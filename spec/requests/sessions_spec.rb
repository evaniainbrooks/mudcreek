require "rails_helper"

RSpec.describe "Sessions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", default: true)
  end

  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "returns 200" do
      get new_session_path

      expect(response).to have_http_status(:ok)
    end

    context "when already signed in" do
      before { post session_path, params: { email_address: user.email_address, password: "password" } }

      it "redirects to admin listings" do
        get new_session_path

        expect(response).to redirect_to(admin_listings_path)
      end
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "redirects to the admin listings page by default" do
        post session_path, params: { email_address: user.email_address, password: "password" }

        expect(response).to redirect_to(admin_listings_path)
      end

      it "sets a signed session cookie" do
        post session_path, params: { email_address: user.email_address, password: "password" }

        expect(cookies[:session_id]).to be_present
      end

      it "creates a session record for the user" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "password" }
        }.to change { user.sessions.count }.by(1)
      end

      context "when return_to_after_authenticating is set" do
        it "redirects to the stored URL" do
          # Trigger request_authentication by visiting a protected path, which stores the URL
          get admin_listings_path
          post session_path, params: { email_address: user.email_address, password: "password" }

          expect(response).to redirect_to(admin_listings_url)
        end
      end
    end

    context "with invalid credentials" do
      it "redirects to the sign-in page" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }

        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "does not create a session record" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong" }
        }.not_to change { user.sessions.count }
      end
    end

    context "with an unknown email address" do
      it "redirects to the sign-in page with an alert" do
        post session_path, params: { email_address: "nobody@example.com", password: "password" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE /session" do
    before { post session_path, params: { email_address: user.email_address, password: "password" } }

    it "redirects to the sign-in page with 303 See Other" do
      delete session_path

      expect(response).to redirect_to(new_session_path)
      expect(response).to have_http_status(:see_other)
    end

    it "destroys the session record" do
      expect { delete session_path }.to change { user.sessions.count }.by(-1)
    end

    it "clears the session cookie" do
      delete session_path

      expect(cookies[:session_id]).to be_blank
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete session_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
