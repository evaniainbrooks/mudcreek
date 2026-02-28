require "rails_helper"

RSpec.describe "Offers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }
  let!(:listing) { create(:listing, pricing_type: :negotiable) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /listings/:listing_hashid/offers" do
    context "with valid params" do
      it "creates a pending offer" do
        expect {
          post listing_offers_path(listing), params: { offer: { amount: "25.00" } }
        }.to change { listing.offers.count }.by(1)
      end

      it "sets amount_cents correctly" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00" } }

        expect(listing.offers.last.amount_cents).to eq(2500)
      end

      it "assigns the offer to the current user" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00" } }

        expect(listing.offers.last.user).to eq(user)
      end

      it "creates the offer in the pending state" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00" } }

        expect(listing.offers.last).to be_pending
      end

      it "stores a message when provided" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00", message: "I'll take it!" } }

        expect(listing.offers.last.message).to eq("I'll take it!")
      end

      it "stores nil message when blank" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00", message: "" } }

        expect(listing.offers.last.message).to be_nil
      end

      it "redirects to the listing with a notice" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00" } }

        expect(response).to redirect_to(listing_path(listing))
        expect(flash[:notice]).to eq("Your offer has been submitted.")
      end
    end

    context "with a zero amount" do
      it "does not create an offer" do
        expect {
          post listing_offers_path(listing), params: { offer: { amount: "0" } }
        }.not_to change { listing.offers.count }
      end

      it "redirects to the listing with an alert" do
        post listing_offers_path(listing), params: { offer: { amount: "0" } }

        expect(response).to redirect_to(listing_path(listing))
        expect(flash[:alert]).to be_present
      end
    end

    context "with a negative amount" do
      it "does not create an offer" do
        expect {
          post listing_offers_path(listing), params: { offer: { amount: "-10" } }
        }.not_to change { listing.offers.count }
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post listing_offers_path(listing), params: { offer: { amount: "25.00" } }

        expect(response).to redirect_to(new_session_path)
      end

      it "does not create an offer" do
        expect {
          post listing_offers_path(listing), params: { offer: { amount: "25.00" } }
        }.not_to change { Offer.count }
      end
    end

    context "when the listing does not exist" do
      it "returns 404" do
        post listing_offers_path(listing_hashid: "nonexistent"), params: { offer: { amount: "25.00" } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
