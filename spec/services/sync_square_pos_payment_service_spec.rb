require "rails_helper"

RSpec.describe SyncSquarePosPaymentService do
  before do
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:square_client) { instance_double("Square::Client") }
  let(:customers_api) { instance_double("Square::Customers::Client") }
  let(:orders_api)    { instance_double("Square::Orders::Client") }

  before do
    allow(SquareClient).to receive(:client).and_return(square_client)
    allow(square_client).to receive(:customers).and_return(customers_api)
    allow(square_client).to receive(:orders).and_return(orders_api)
  end

  let(:payment_id) { "sq_pos_abc" }
  let(:payment_data) do
    {
      "id"              => payment_id,
      "status"          => "COMPLETED",
      "amount_money"    => { "amount" => 2500 },
      "total_tax_money" => { "amount" => 250 }
    }
  end

  subject(:call) { described_class.call(payment_data: payment_data, tenant: Current.tenant) }

  # ------------------------------------------------------------------ #
  describe "idempotency" do
    before { create(:order, square_payment_id: payment_id, status: "paid", source: "pos", total_cents: 2500) }

    it "does not create a duplicate order" do
      expect { call }.not_to change(Order, :count)
    end
  end

  # ------------------------------------------------------------------ #
  describe "without a customer_id" do
    it "creates one paid POS order" do
      expect { call }.to change(Order, :count).by(1)
    end

    it "sets source to pos and status to paid" do
      call
      order = Order.last
      expect(order.source).to eq("pos")
      expect(order.status).to eq("paid")
    end

    it "generates a placeholder guest email" do
      call
      expect(Order.last.guest_email).to match(/\Aposanon[a-f0-9]+@pos\.local\z/)
    end

    it "creates a succeeded transaction" do
      expect { call }.to change(Transaction, :count).by(1)
      expect(Transaction.last.state).to eq("succeeded")
      expect(Transaction.last.square_payment_id).to eq(payment_id)
    end

    it "stores the raw payment in the transaction" do
      call
      expect(Transaction.last.raw_response).to eq(payment_data)
    end

    it "sets total_cents from amount_money" do
      call
      expect(Order.last.total_cents).to eq(2500)
    end

    it "derives subtotal_cents as total minus tax" do
      call
      expect(Order.last.subtotal_cents).to eq(2250)
      expect(Order.last.tax_cents).to eq(250)
    end

    it "creates a fallback POS Sale order item" do
      call
      expect(Order.last.order_items.first.name).to eq("POS Sale")
    end
  end

  # ------------------------------------------------------------------ #
  describe "user matching" do
    let(:customer_id) { "cust_123" }
    let(:payment_data) { super().merge("customer_id" => customer_id) }

    context "when the Square customer email matches a user" do
      let!(:user) { create(:user, email_address: "buyer@example.com") }

      before do
        customer = double(email_address: "buyer@example.com")
        allow(customers_api).to receive(:get)
          .with(customer_id: customer_id)
          .and_return(double(customer: customer))
      end

      it "links the order to the matched user" do
        call
        expect(Order.last.user).to eq(user)
      end

      it "does not set guest_email" do
        call
        expect(Order.last.guest_email).to be_nil
      end
    end

    context "when the Square customer email does not match any user" do
      before do
        customer = double(email_address: "stranger@example.com")
        allow(customers_api).to receive(:get)
          .with(customer_id: customer_id)
          .and_return(double(customer: customer))
      end

      it "creates a guest order with the customer email" do
        call
        order = Order.last
        expect(order.user).to be_nil
        expect(order.guest_email).to eq("stranger@example.com")
      end
    end

    context "when the Square customer has no email address" do
      before do
        customer = double(email_address: nil)
        allow(customers_api).to receive(:get)
          .with(customer_id: customer_id)
          .and_return(double(customer: customer))
      end

      it "falls back to a placeholder email" do
        call
        expect(Order.last.guest_email).to match(/@pos\.local/)
      end
    end

    context "when the customers API raises an error" do
      before do
        allow(customers_api).to receive(:get)
          .and_raise(Square::Errors::ResponseError.new("{}", code: 404))
      end

      it "still creates an order with a placeholder email" do
        expect { call }.to change(Order, :count).by(1)
        expect(Order.last.guest_email).to match(/@pos\.local/)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "line items" do
    context "when the payment has an order_id" do
      let(:payment_data) { super().merge("order_id" => "sq_order_999") }

      let(:line_items) do
        [
          double(name: "Boots", variation_name: "Size 10", base_price_money: double(amount: 1500)),
          double(name: "Hat",   variation_name: nil,       base_price_money: double(amount: 1000))
        ]
      end

      before do
        sq_order = double(line_items: line_items)
        allow(orders_api).to receive(:get)
          .with(order_id: "sq_order_999")
          .and_return(double(order: sq_order))
      end

      it "creates one order item per line item" do
        call
        expect(Order.last.order_items.count).to eq(2)
      end

      it "combines name and variation_name with an em-dash" do
        call
        names = Order.last.order_items.pluck(:name)
        expect(names).to contain_exactly("Boots – Size 10", "Hat")
      end
    end

    context "when the payment has no order_id" do
      it "creates a single POS Sale item for the full amount" do
        call
        item = Order.last.order_items.sole
        expect(item.name).to eq("POS Sale")
        expect(item.price_cents).to eq(2500)
      end
    end

    context "when the orders API raises an error" do
      let(:payment_data) { super().merge("order_id" => "sq_order_bad") }

      before do
        allow(orders_api).to receive(:get)
          .and_raise(Square::Errors::ResponseError.new("{}", code: 500))
      end

      it "falls back to a single POS Sale item" do
        call
        expect(Order.last.order_items.first.name).to eq("POS Sale")
      end
    end
  end
end
