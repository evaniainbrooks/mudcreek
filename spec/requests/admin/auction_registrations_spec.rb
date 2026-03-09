require "rails_helper"

RSpec.describe "Admin::AuctionRegistrations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:role) do
    Role.create!(name: "reg_viewer", description: "View registrations").tap do |r|
      r.permissions.create!(resource: "AuctionRegistration", action: "index")
    end
  end
  let(:user) { create(:user, role: role) }
  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/auction_registrations" do
    it "returns 200" do
      get admin_auction_registrations_path
      expect(response).to have_http_status(:ok)
    end

    it "responds with turbo_stream when requested" do
      get admin_auction_registrations_path,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.content_type).to include("turbo-stream")
    end

    context "with a ransack state filter" do
      let(:auction)  { create(:auction) }
      let(:reg_user) { create(:user) }
      before { AuctionRegistration.create!(auction: auction, user: reg_user, state: "approved") }

      it "returns 200" do
        get admin_auction_registrations_path, params: { q: { state_eq: "approved" } }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }
      it "redirects to sign-in" do
        get admin_auction_registrations_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }
      it "raises Pundit::NotAuthorizedError" do
        expect {
          get admin_auction_registrations_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/auction_registrations/:id" do
    let(:update_role) do
      Role.create!(name: "reg_manager", description: "Manage registrations").tap do |r|
        r.permissions.create!(resource: "AuctionRegistration", action: "update")
      end
    end
    let(:user) { create(:user, role: update_role) }

    let(:auction)      { create(:auction) }
    let(:reg_user)     { create(:user) }
    let(:registration) { AuctionRegistration.create!(auction: auction, user: reg_user, state: "pending") }

    context "with HTML format" do
      it "updates the state and redirects" do
        patch admin_auction_registration_path(registration),
          params: { auction_registration: { state: "approved" } }

        expect(registration.reload.state).to eq("approved")
        expect(response).to redirect_to(admin_auction_registrations_path)
      end

      it "updates admin_notes" do
        patch admin_auction_registration_path(registration),
          params: { auction_registration: { admin_notes: "Verified by phone." } }

        expect(registration.reload.admin_notes).to eq("Verified by phone.")
      end
    end

    context "with turbo_stream format" do
      it "responds with turbo_stream" do
        patch admin_auction_registration_path(registration),
          params: { auction_registration: { state: "approved" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to include("turbo-stream")
        expect(registration.reload.state).to eq("approved")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_auction_registration_path(registration),
          params: { auction_registration: { state: "approved" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:update_role) { Role.create!(name: "read_only_reg", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_auction_registration_path(registration),
            params: { auction_registration: { state: "approved" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
