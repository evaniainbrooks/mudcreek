require "rails_helper"

RSpec.describe RentalPricingService do
  def plan(duration_minutes:, price_cents:)
    instance_double(Listings::RentalRatePlan,
      duration_minutes: duration_minutes,
      price_cents: price_cents)
  end

  let(:hourly) { plan(duration_minutes: 60, price_cents: 1500) }
  let(:half)   { plan(duration_minutes: 30, price_cents: 1000) }

  subject(:service) { described_class.new([hourly]) }

  describe "#minimum_cost_for" do
    context "when duration is zero" do
      it "returns zero cost with an empty breakdown" do
        result = service.minimum_cost_for(0)
        expect(result.total_cents).to eq(0)
        expect(result.breakdown).to be_empty
      end
    end

    context "when duration is negative" do
      it "returns zero cost with an empty breakdown" do
        result = service.minimum_cost_for(-30)
        expect(result.total_cents).to eq(0)
        expect(result.breakdown).to be_empty
      end
    end

    context "with a single rate plan" do
      it "returns the plan price for an exact match" do
        result = service.minimum_cost_for(60)
        expect(result.total_cents).to eq(1500)
      end

      it "uses two units for double the duration" do
        result = service.minimum_cost_for(120)
        expect(result.total_cents).to eq(3000)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: hourly, quantity: 2 }
        )
      end

      it "charges one plan when duration is less than one unit (rounds up via dp)" do
        result = service.minimum_cost_for(30)
        expect(result.total_cents).to eq(1500)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: hourly, quantity: 1 }
        )
      end
    end

    context "with multiple rate plans" do
      subject(:service) { described_class.new([hourly, half]) }

      it "picks the cheaper single plan for 30 minutes" do
        result = service.minimum_cost_for(30)
        expect(result.total_cents).to eq(1000)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: half, quantity: 1 }
        )
      end

      it "picks the single hourly plan over two half-hour plans" do
        result = service.minimum_cost_for(60)
        expect(result.total_cents).to eq(1500)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: hourly, quantity: 1 }
        )
      end

      it "combines plans optimally for 90 minutes" do
        result = service.minimum_cost_for(90)
        expect(result.total_cents).to eq(2500)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: hourly, quantity: 1 },
          { rate_plan: half,   quantity: 1 }
        )
      end
    end

    context "when the cheaper plan is longer" do
      let(:cheap_hour) { plan(duration_minutes: 60, price_cents: 900) }
      subject(:service) { described_class.new([half, cheap_hour]) }

      it "uses two cheap hourly plans rather than mixing in the pricier half-hour" do
        # 90 min: 2×cheap_hour(1800) < cheap_hour+half(1900) < 3×half(3000)
        result = service.minimum_cost_for(90)
        expect(result.total_cents).to eq(1800)
        expect(result.breakdown).to contain_exactly(
          { rate_plan: cheap_hour, quantity: 2 }
        )
      end
    end

    describe "return value shape" do
      it "returns a Result with total_cents and breakdown" do
        result = service.minimum_cost_for(60)
        expect(result).to respond_to(:total_cents, :breakdown)
      end

      it "includes rate_plan and quantity keys in each breakdown entry" do
        result = service.minimum_cost_for(60)
        entry = result.breakdown.first
        expect(entry).to include(:rate_plan, :quantity)
      end
    end
  end
end
