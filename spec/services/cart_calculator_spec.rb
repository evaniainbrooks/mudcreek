require "rails_helper"

RSpec.describe CartCalculator do
  def item(price_cents:, tax_exempt: false)
    listing = instance_double(Listing, tax_exempt?: tax_exempt)
    instance_double(CartItem, effective_price: Money.new(price_cents), listing: listing)
  end

  def discount(fixed:, amount_cents:)
    instance_double(DiscountCode,
      fixed?: fixed,
      percentage?: !fixed,
      amount_cents: amount_cents)
  end

  def delivery(price_cents:)
    instance_double(DeliveryMethod, price_cents: price_cents)
  end

  describe "#calculate" do
    context "empty cart" do
      it "returns all zeros" do
        result = described_class.new([]).calculate
        expect(result.subtotal_cents).to eq(0)
        expect(result.tax_cents).to eq(0)
        expect(result.discount_cents).to eq(0)
        expect(result.delivery_cents).to eq(0)
        expect(result.total_cents).to eq(0)
      end
    end

    context "single taxable item" do
      let(:items) { [item(price_cents: 1000)] }

      it "calculates subtotal, tax, and total correctly" do
        result = described_class.new(items).calculate
        expected_tax = (1000 * SALES_TAX_RATE).ceil
        expect(result.subtotal_cents).to eq(1000)
        expect(result.tax_cents).to eq(expected_tax)
        expect(result.total_cents).to eq(1000 + expected_tax)
      end
    end

    context "tax-exempt item" do
      let(:items) { [item(price_cents: 1000, tax_exempt: true)] }

      it "applies no tax" do
        result = described_class.new(items).calculate
        expect(result.tax_cents).to eq(0)
        expect(result.total_cents).to eq(1000)
      end
    end

    context "fixed discount" do
      let(:items) { [item(price_cents: 1000)] }
      let(:pretax_total) { 1000 + (1000 * SALES_TAX_RATE).ceil }

      it "subtracts discount from pretax total" do
        code = discount(fixed: true, amount_cents: 200)
        result = described_class.new(items, discount_code: code).calculate
        expect(result.discount_cents).to eq(200)
        expect(result.total_cents).to eq(pretax_total - 200)
      end

      it "caps discount at pretax total so total never goes below zero" do
        code = discount(fixed: true, amount_cents: 999_999)
        result = described_class.new(items, discount_code: code).calculate
        expect(result.discount_cents).to eq(pretax_total)
        expect(result.total_cents).to eq(0)
      end
    end

    context "percentage discount" do
      let(:items) { [item(price_cents: 10_000)] }

      it "floors the discount to whole cents" do
        # 10% discount: amount_cents = 1000 (stored as basis points × 100)
        code = discount(fixed: false, amount_cents: 1000)
        result = described_class.new(items, discount_code: code).calculate
        pretax = 10_000 + (10_000 * SALES_TAX_RATE).ceil
        expected_discount = (pretax * 1000 / 10_000.0).floor
        expect(result.discount_cents).to eq(expected_discount)
      end
    end

    context "delivery method" do
      let(:items) { [item(price_cents: 1000)] }

      it "adds delivery price to total" do
        dm = delivery(price_cents: 500)
        result = described_class.new(items, delivery_method: dm).calculate
        pretax = 1000 + (1000 * SALES_TAX_RATE).ceil
        expect(result.delivery_cents).to eq(500)
        expect(result.total_cents).to eq(pretax + 500)
      end
    end

    context "discount + delivery combined" do
      let(:items) { [item(price_cents: 2000)] }

      it "applies discount then adds delivery" do
        code = discount(fixed: true, amount_cents: 300)
        dm   = delivery(price_cents: 400)
        result = described_class.new(items, discount_code: code, delivery_method: dm).calculate
        pretax = 2000 + (2000 * SALES_TAX_RATE).ceil
        expect(result.total_cents).to eq(pretax - 300 + 400)
      end
    end

    context "large discount exceeding pretax total" do
      let(:items) { [item(price_cents: 100)] }

      it "floors total at zero (no delivery)" do
        code = discount(fixed: true, amount_cents: 999_999)
        result = described_class.new(items, discount_code: code).calculate
        expect(result.total_cents).to eq(0)
      end

      it "still charges delivery when discount wipes out the subtotal+tax" do
        code = discount(fixed: true, amount_cents: 999_999)
        dm   = delivery(price_cents: 50)
        result = described_class.new(items, discount_code: code, delivery_method: dm).calculate
        expect(result.total_cents).to eq(50)
      end
    end

    it "returns Money objects for monetary fields" do
      result = described_class.new([item(price_cents: 500)]).calculate
      expect(result.subtotal).to be_a(Money)
      expect(result.tax).to be_a(Money)
      expect(result.discount_savings).to be_a(Money)
      expect(result.delivery).to be_a(Money)
      expect(result.total).to be_a(Money)
    end
  end
end
