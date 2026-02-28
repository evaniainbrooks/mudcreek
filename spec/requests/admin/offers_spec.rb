require "rails_helper"

RSpec.describe "Admin::Offers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "offer_manager", description: "Manage offers").tap do |r|
      r.permissions.create!(resource: "Offer", action: "index")
      r.permissions.create!(resource: "Offer", action: "show")
      r.permissions.create!(resource: "Offer", action: "update")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:offer) { create(:offer) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/offers" do
    it "returns 200" do
      get admin_offers_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the offer in the response" do
      get admin_offers_path

      expect(response.body).to include(offer.listing.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_offers_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_offers", description: "No offer access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_offers_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/offers/:id" do
    it "returns 200" do
      get admin_offer_path(offer)

      expect(response).to have_http_status(:ok)
    end

    it "displays the offer amount" do
      get admin_offer_path(offer)

      expect(response.body).to include(offer.user.email_address)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_offer_path(offer)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_offers", description: "No offer access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_offer_path(offer) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/offers/:id" do
    context "accepting a pending offer" do
      it "transitions the offer to accepted" do
        patch admin_offer_path(offer), params: { state: "accepted" }

        expect(offer.reload).to be_accepted
      end

      it "marks the listing as sold" do
        patch admin_offer_path(offer), params: { state: "accepted" }

        expect(offer.listing.reload).to be_sold
      end

      it "redirects to the offer with a notice" do
        patch admin_offer_path(offer), params: { state: "accepted" }

        expect(response).to redirect_to(admin_offer_path(offer))
        expect(flash[:notice]).to eq("Offer accepted.")
      end
    end

    context "declining a pending offer" do
      it "transitions the offer to declined" do
        patch admin_offer_path(offer), params: { state: "declined" }

        expect(offer.reload).to be_declined
      end

      it "redirects to the offer with a notice" do
        patch admin_offer_path(offer), params: { state: "declined" }

        expect(response).to redirect_to(admin_offer_path(offer))
        expect(flash[:notice]).to eq("Offer declined.")
      end
    end

    context "marking an accepted offer as pending" do
      let!(:offer) { create(:offer, state: "accepted") }

      it "transitions the offer back to pending" do
        patch admin_offer_path(offer), params: { state: "pending" }

        expect(offer.reload).to be_pending
      end
    end

    context "declining an accepted offer" do
      let!(:offer) { create(:offer, state: "accepted") }

      it "transitions the offer to declined" do
        patch admin_offer_path(offer), params: { state: "declined" }

        expect(offer.reload).to be_declined
      end
    end

    context "accepting a declined offer" do
      let!(:offer) { create(:offer, state: "declined") }

      it "transitions the offer to accepted" do
        patch admin_offer_path(offer), params: { state: "accepted" }

        expect(offer.reload).to be_accepted
      end
    end

    context "with an invalid state" do
      it "does not change the offer state" do
        expect {
          patch admin_offer_path(offer), params: { state: "invalid" }
        }.not_to change { offer.reload.state }
      end

      it "redirects with an alert" do
        patch admin_offer_path(offer), params: { state: "invalid" }

        expect(response).to redirect_to(admin_offer_path(offer))
        expect(flash[:alert]).to eq("Invalid state.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_offer_path(offer), params: { state: "accepted" }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_offers", description: "Read-only offer access").tap do |r|
          r.permissions.create!(resource: "Offer", action: "index")
          r.permissions.create!(resource: "Offer", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_offer_path(offer), params: { state: "accepted" }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
