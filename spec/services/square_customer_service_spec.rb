require "rails_helper"

RSpec.describe SquareCustomerService do
  before do
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }
  subject(:service) { described_class.new(user) }

  let(:square_client) { double("Square::Client") }
  let(:customers_api)  { double("Square::CustomersApi") }
  let(:cards_api)      { double("Square::CardsApi") }

  before do
    allow(SquareClient).to receive(:client).and_return(square_client)
    allow(square_client).to receive(:customers).and_return(customers_api)
    allow(square_client).to receive(:cards).and_return(cards_api)
  end

  def square_error(detail: "Something went wrong")
    msg = JSON.generate({ errors: [ { detail: detail } ] })
    Square::Errors::ResponseError.new(msg, code: 422)
  end

  # ------------------------------------------------------------------ #
  describe "#find_or_create_customer!" do
    context "when the user already has a square_customer_id" do
      before { user.update_column(:square_customer_id, "existing_cust_123") }

      it "returns the existing id without calling the API" do
        expect(customers_api).not_to receive(:create)

        result = service.find_or_create_customer!

        expect(result).to eq("existing_cust_123")
      end
    end

    context "when the user has no square_customer_id" do
      let(:customer_response) { double(customer: double(id: "new_cust_456")) }

      before do
        allow(customers_api).to receive(:create).and_return(customer_response)
      end

      it "calls the Square API with the user's name and email" do
        expect(customers_api).to receive(:create).with(
          given_name:    user.first_name,
          family_name:   user.last_name,
          email_address: user.email_address
        ).and_return(customer_response)

        service.find_or_create_customer!
      end

      it "persists the returned customer id on the user" do
        service.find_or_create_customer!

        expect(user.reload.square_customer_id).to eq("new_cust_456")
      end

      it "returns the new customer id" do
        expect(service.find_or_create_customer!).to eq("new_cust_456")
      end

      context "when the Square API returns an error" do
        before { allow(customers_api).to receive(:create).and_raise(square_error(detail: "Invalid email")) }

        it "raises SquareCustomerService::Error" do
          expect { service.find_or_create_customer! }.to raise_error(SquareCustomerService::Error, "Invalid email")
        end
      end

      context "when the error JSON has no detail field" do
        before { allow(customers_api).to receive(:create).and_raise(Square::Errors::ResponseError.new("{}", code: 500)) }

        it "raises SquareCustomerService::Error with a fallback message" do
          expect { service.find_or_create_customer! }.to raise_error(SquareCustomerService::Error, "Square API error.")
        end
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "#create_card" do
    let(:card)            { double("Square::Card", id: "card_789") }
    let(:card_response)   { double(card: card) }

    before do
      user.update_column(:square_customer_id, "cust_abc")
      allow(cards_api).to receive(:create).and_return(card_response)
    end

    it "creates the card with the correct customer id and cardholder name" do
      expect(cards_api).to receive(:create).with(
        idempotency_key: instance_of(String),
        source_id: "src_token",
        card: { customer_id: "cust_abc", cardholder_name: user.name }
      ).and_return(card_response)

      service.create_card(source_id: "src_token")
    end

    it "returns the card object" do
      result = service.create_card(source_id: "src_token")

      expect(result).to eq(card)
    end

    it "uses a unique idempotency key each call" do
      keys = 2.times.map do
        k = nil
        allow(cards_api).to receive(:create) do |args|
          k = args[:idempotency_key]
          card_response
        end
        service.create_card(source_id: "src_token")
        k
      end

      expect(keys.uniq.size).to eq(2)
    end

    context "when the Square API returns an error" do
      before { allow(cards_api).to receive(:create).and_raise(square_error(detail: "Card declined")) }

      it "raises SquareCustomerService::Error" do
        expect { service.create_card(source_id: "src_token") }.to raise_error(SquareCustomerService::Error, "Card declined")
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "#list_cards" do
    context "when the user has no square_customer_id" do
      it "returns an empty array without calling the API" do
        expect(cards_api).not_to receive(:list)

        expect(service.list_cards).to eq([])
      end
    end

    context "when the user has a square_customer_id" do
      let(:card_a) { double("Card A") }
      let(:card_b) { double("Card B") }
      let(:list_response) { double(to_a: [ card_a, card_b ]) }

      before do
        user.update_column(:square_customer_id, "cust_abc")
        allow(cards_api).to receive(:list).with(customer_id: "cust_abc").and_return(list_response)
      end

      it "returns the cards from the API" do
        expect(service.list_cards).to eq([ card_a, card_b ])
      end

      context "when the Square API returns an error" do
        before { allow(cards_api).to receive(:list).and_raise(square_error(detail: "Unauthorized")) }

        it "raises SquareCustomerService::Error" do
          expect { service.list_cards }.to raise_error(SquareCustomerService::Error, "Unauthorized")
        end
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "#disable_card" do
    before do
      allow(cards_api).to receive(:disable)
    end

    it "calls the Square API to disable the card" do
      expect(cards_api).to receive(:disable).with(card_id: "card_xyz")

      service.disable_card(card_id: "card_xyz")
    end

    context "when the disabled card is the user's default card" do
      before { user.update_column(:default_square_card_id, "card_xyz") }

      it "clears the default_square_card_id" do
        service.disable_card(card_id: "card_xyz")

        expect(user.reload.default_square_card_id).to be_nil
      end
    end

    context "when the disabled card is not the user's default card" do
      before { user.update_column(:default_square_card_id, "card_other") }

      it "does not change the default_square_card_id" do
        service.disable_card(card_id: "card_xyz")

        expect(user.reload.default_square_card_id).to eq("card_other")
      end
    end

    context "when the user has no default card" do
      it "does not error" do
        expect { service.disable_card(card_id: "card_xyz") }.not_to raise_error
      end
    end

    context "when the Square API returns an error" do
      before { allow(cards_api).to receive(:disable).and_raise(square_error(detail: "Card not found")) }

      it "raises SquareCustomerService::Error" do
        expect { service.disable_card(card_id: "card_xyz") }.to raise_error(SquareCustomerService::Error, "Card not found")
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "#set_default_card" do
    it "updates the user's default_square_card_id" do
      service.set_default_card(card_id: "card_new_default")

      expect(user.reload.default_square_card_id).to eq("card_new_default")
    end

    it "overwrites an existing default card" do
      user.update_column(:default_square_card_id, "card_old")

      service.set_default_card(card_id: "card_new_default")

      expect(user.reload.default_square_card_id).to eq("card_new_default")
    end
  end
end
