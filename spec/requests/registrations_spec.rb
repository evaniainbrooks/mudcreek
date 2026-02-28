require "rails_helper"

RSpec.describe "Registrations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:valid_params) do
    {
      user: {
        first_name: "Jane",
        last_name: "Doe",
        email_address: "jane@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }
  end

  describe "POST /registration" do
    context "with valid params" do
      it "creates a new user" do
        expect {
          post registration_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates the user without an activated_at timestamp" do
        post registration_path, params: valid_params

        expect(User.last.activated_at).to be_nil
      end

      it "enqueues an activation email" do
        expect {
          post registration_path, params: valid_params
        }.to have_enqueued_mail(RegistrationsMailer, :activate)
      end

      it "redirects to the sign-in page" do
        post registration_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end

      it "sets a notice" do
        post registration_path, params: valid_params

        expect(flash[:notice]).to eq("Check your email for an activation link.")
      end

      it "does not start a session" do
        post registration_path, params: valid_params

        expect(cookies[:session_id]).to be_blank
      end
    end

    context "with a missing first name" do
      let(:params) { { user: valid_params[:user].merge(first_name: "") } }

      it "redirects to the sign-in page" do
        post registration_path, params: params

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        post registration_path, params: params

        expect(flash[:alert]).to be_present
      end

      it "does not create a user" do
        expect {
          post registration_path, params: params
        }.not_to change(User, :count)
      end
    end

    context "with a missing email address" do
      let(:params) { { user: valid_params[:user].merge(email_address: "") } }

      it "redirects to the sign-in page" do
        post registration_path, params: params

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        post registration_path, params: params

        expect(flash[:alert]).to be_present
      end

      it "does not create a user" do
        expect {
          post registration_path, params: params
        }.not_to change(User, :count)
      end
    end

    context "with mismatched passwords" do
      let(:params) { { user: valid_params[:user].merge(password_confirmation: "different") } }

      it "redirects to the sign-in page" do
        post registration_path, params: params

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        post registration_path, params: params

        expect(flash[:alert]).to be_present
      end

      it "does not create a user" do
        expect {
          post registration_path, params: params
        }.not_to change(User, :count)
      end
    end

    context "with a duplicate email address" do
      before { create(:user, email_address: "jane@example.com") }

      it "redirects to the sign-in page" do
        post registration_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert" do
        post registration_path, params: valid_params

        expect(flash[:alert]).to be_present
      end

      it "does not create a user" do
        expect {
          post registration_path, params: valid_params
        }.not_to change(User, :count)
      end
    end
  end
end
