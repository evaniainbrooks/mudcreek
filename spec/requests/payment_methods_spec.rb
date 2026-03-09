require "rails_helper"

RSpec.describe "PaymentMethods", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  let(:service) { instance_double(SquareCustomerService) }

  before do
    allow(SquareCustomerService).to receive(:new).with(user).and_return(service)
  end

  describe "POST /profile/payment_methods" do
    let(:fake_card) { double("card", id: "card_abc123", last_4: "4242") }

    context "when the card is created successfully" do
      before { allow(service).to receive(:create_card).with(source_id: "tok_123").and_return(fake_card) }

      context "when the user has no default card yet" do
        before do
          allow(service).to receive(:set_default_card).with(card_id: "card_abc123")
        end

        it "sets the new card as default" do
          post profile_payment_methods_path, params: { source_id: "tok_123" }

          expect(service).to have_received(:set_default_card).with(card_id: "card_abc123")
        end

        it "redirects with a notice" do
          post profile_payment_methods_path, params: { source_id: "tok_123" }

          expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
          expect(flash[:notice]).to eq("Card ending in 4242 added.")
        end
      end

      context "when the user already has a default card" do
        before { user.update_column(:default_square_card_id, "card_existing") }

        it "does not overwrite the existing default" do
          expect(service).not_to receive(:set_default_card)

          post profile_payment_methods_path, params: { source_id: "tok_123" }
        end

        it "redirects with a notice" do
          post profile_payment_methods_path, params: { source_id: "tok_123" }

          expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
          expect(flash[:notice]).to eq("Card ending in 4242 added.")
        end
      end
    end

    context "when Square returns an error" do
      before do
        allow(service).to receive(:create_card)
          .and_raise(SquareCustomerService::Error, "Card declined.")
      end

      it "redirects with an alert" do
        post profile_payment_methods_path, params: { source_id: "tok_bad" }

        expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
        expect(flash[:alert]).to eq("Card declined.")
      end

      it "does not set a default card" do
        expect(service).not_to receive(:set_default_card)

        post profile_payment_methods_path, params: { source_id: "tok_bad" }
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post profile_payment_methods_path, params: { source_id: "tok_123" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /profile/payment_methods/:id/set_default" do
    before { allow(service).to receive(:set_default_card).with(card_id: "card_abc123") }

    it "calls set_default_card on the service" do
      patch set_default_profile_payment_method_path("card_abc123")

      expect(service).to have_received(:set_default_card).with(card_id: "card_abc123")
    end

    it "redirects with a notice" do
      patch set_default_profile_payment_method_path("card_abc123")

      expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
      expect(flash[:notice]).to eq("Default card updated.")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch set_default_profile_payment_method_path("card_abc123")

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /profile/payment_methods/:id" do
    context "when the card is disabled successfully" do
      before { allow(service).to receive(:disable_card).with(card_id: "card_abc123") }

      it "calls disable_card on the service" do
        delete profile_payment_method_path("card_abc123")

        expect(service).to have_received(:disable_card).with(card_id: "card_abc123")
      end

      it "redirects with a notice" do
        delete profile_payment_method_path("card_abc123")

        expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
        expect(flash[:notice]).to eq("Card removed.")
      end
    end

    context "when Square returns an error" do
      before do
        allow(service).to receive(:disable_card)
          .and_raise(SquareCustomerService::Error, "Card not found.")
      end

      it "redirects with an alert" do
        delete profile_payment_method_path("card_abc123")

        expect(response).to redirect_to(edit_profile_path(anchor: "payment-methods"))
        expect(flash[:alert]).to eq("Card not found.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete profile_payment_method_path("card_abc123")

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
