require "rails_helper"

RSpec.describe "Podium", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  describe "GET /podium" do
    it "returns 200" do
      get podium_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the Podium heading" do
      get podium_path

      expect(response.body).to include("Podium")
    end

    it "is accessible without signing in" do
      get podium_path

      expect(response).to have_http_status(:ok)
    end

    it "is accessible when signed in" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get podium_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /podium" do
    let(:contact_params) do
      { name: "Alice", email: "alice@example.com", message: "Interested in Podium." }
    end

    before do
      allow(PodiumMailer).to receive_message_chain(:contact, :deliver_later)
    end

    it "enqueues a contact email" do
      post podium_path, params: contact_params

      expect(PodiumMailer).to have_received(:contact)
    end

    it "redirects to the podium page" do
      post podium_path, params: contact_params

      expect(response).to redirect_to(podium_path)
    end

    it "sets a flash notice" do
      post podium_path, params: contact_params

      expect(flash[:notice]).to be_present
    end

    it "is accessible without signing in" do
      post podium_path, params: contact_params

      expect(response).to redirect_to(podium_path)
    end
  end
end
