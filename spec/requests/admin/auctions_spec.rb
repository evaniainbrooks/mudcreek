require "rails_helper"

RSpec.describe "Admin::Auctions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "auction_manager", description: "Manage auctions").tap do |r|
      r.permissions.create!(resource: "Auction", action: "index")
      r.permissions.create!(resource: "Auction", action: "show")
      r.permissions.create!(resource: "Auction", action: "create")
      r.permissions.create!(resource: "Auction", action: "update")
      r.permissions.create!(resource: "Auction", action: "destroy")
    end
  end

  let(:user)    { create(:user, role: role) }
  let!(:auction) { create(:auction) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/auctions" do
    it "returns 200" do
      get admin_auctions_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the auction name" do
      get admin_auctions_path

      expect(response.body).to include(auction.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_auctions_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_auctions", description: "No auction access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_auctions_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/auctions/:hashid" do
    it "returns 200" do
      get admin_auction_path(auction)

      expect(response).to have_http_status(:ok)
    end

    it "includes the auction name" do
      get admin_auction_path(auction)

      expect(response.body).to include(auction.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_auction_path(auction)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/auctions/new" do
    it "returns 200" do
      get new_admin_auction_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/auctions" do
    context "with valid params" do
      let(:valid_params) { { auction: { name: "Spring Auction" } } }

      it "creates a new auction" do
        expect {
          post admin_auctions_path, params: valid_params
        }.to change(Auction, :count).by(1)
      end

      it "redirects to the auction show page" do
        post admin_auctions_path, params: valid_params

        expect(response).to redirect_to(admin_auction_path(Auction.last))
      end

      it "sets a success notice" do
        post admin_auctions_path, params: valid_params

        expect(flash[:notice]).to include("successfully created")
      end
    end

    context "with ends_at before starts_at" do
      let(:invalid_params) do
        { auction: { name: "Bad Dates", starts_at: 1.day.from_now, ends_at: Time.current } }
      end

      it "does not create an auction" do
        expect {
          post admin_auctions_path, params: invalid_params
        }.not_to change(Auction, :count)
      end

      it "re-renders new with unprocessable entity status" do
        post admin_auctions_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with a blank name" do
      it "does not create an auction" do
        expect {
          post admin_auctions_path, params: { auction: { name: "" } }
        }.not_to change(Auction, :count)
      end
    end

    context "reconciler scheduling" do
      let(:timezone)        { "Pacific Time (US & Canada)" }
      let(:ends_at_str)     { "2026-09-01 14:00" }
      let(:expected_run_at) { ActiveSupport::TimeZone[timezone].parse(ends_at_str) }

      context "when ends_at and timezone are provided" do
        it "enqueues AuctionReconcilerJob at the UTC-equivalent of the local end time" do
          expect {
            post admin_auctions_path, params: {
              auction: {
                name: "Fall Auction",
                starts_at: "2026-09-01 10:00",
                ends_at: ends_at_str,
                timezone: timezone
              }
            }
          }.to have_enqueued_job(AuctionReconcilerJob).at(expected_run_at)
        end
      end

      context "when ends_at is not provided" do
        it "does not enqueue AuctionReconcilerJob" do
          expect {
            post admin_auctions_path, params: { auction: { name: "Undated Auction" } }
          }.not_to have_enqueued_job(AuctionReconcilerJob)
        end
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_auctions_path, params: { auction: { name: "Spring Auction" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_auctions", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Auction", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_auctions_path, params: { auction: { name: "Spring Auction" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/auctions/:hashid/edit" do
    it "returns 200" do
      get edit_admin_auction_path(auction)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/auctions/:hashid" do
    context "with valid params" do
      it "updates the auction name" do
        patch admin_auction_path(auction), params: { auction: { name: "Renamed Auction" } }

        expect(auction.reload.name).to eq("Renamed Auction")
      end

      it "redirects to the show page with a notice" do
        patch admin_auction_path(auction), params: { auction: { name: "Renamed Auction" } }

        expect(response).to redirect_to(admin_auction_path(auction))
        expect(flash[:notice]).to include("successfully updated")
      end
    end

    context "setting published and reconciled flags" do
      it "marks the auction as published" do
        patch admin_auction_path(auction), params: { auction: { published: true } }

        expect(auction.reload.published).to be true
      end

      it "marks the auction as reconciled" do
        patch admin_auction_path(auction), params: { auction: { reconciled: true } }

        expect(auction.reload.reconciled).to be true
      end
    end

    context "with ends_at before starts_at" do
      it "does not update and re-renders edit" do
        patch admin_auction_path(auction), params: {
          auction: { starts_at: 1.day.from_now, ends_at: Time.current }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "reconciler scheduling" do
      # Auction factory default timezone is "Eastern Time (US & Canada)"
      let(:auction) do
        create(:auction,
          timezone:   "Eastern Time (US & Canada)",
          starts_at:  "2026-10-01 09:00:00 -0400",
          ends_at:    "2026-10-01 17:00:00 -0400")
      end

      context "when ends_at is changed" do
        let(:new_ends_at_str) { "2026-10-02 18:00" }
        let(:expected_run_at) { ActiveSupport::TimeZone["Eastern Time (US & Canada)"].parse(new_ends_at_str) }

        it "enqueues AuctionReconcilerJob at the new end time in the auction's timezone" do
          expect {
            patch admin_auction_path(auction), params: {
              auction: {
                ends_at:  new_ends_at_str,
                timezone: "Eastern Time (US & Canada)"
              }
            }
          }.to have_enqueued_job(AuctionReconcilerJob).at(expected_run_at)
        end
      end

      context "when ends_at is not changed" do
        it "does not enqueue AuctionReconcilerJob" do
          clear_enqueued_jobs

          expect {
            patch admin_auction_path(auction), params: { auction: { name: "Renamed Auction" } }
          }.not_to have_enqueued_job(AuctionReconcilerJob)
        end
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_auction_path(auction), params: { auction: { name: "Renamed" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_auctions", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Auction", action: "index")
          r.permissions.create!(resource: "Auction", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_auction_path(auction), params: { auction: { name: "Renamed" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/auctions/:hashid" do
    it "destroys the auction" do
      expect {
        delete admin_auction_path(auction)
      }.to change(Auction, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_auction_path(auction)

      expect(response).to redirect_to(admin_auctions_path)
      expect(flash[:notice]).to include("successfully deleted")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_auction_path(auction)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_auctions", description: "Read-only").tap do |r|
          r.permissions.create!(resource: "Auction", action: "index")
          r.permissions.create!(resource: "Auction", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_auction_path(auction)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
