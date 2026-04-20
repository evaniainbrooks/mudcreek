require "rails_helper"

RSpec.describe Subscriptions::AdvanceService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:plan) { create(:subscription_plan, subscription_type: :month_to_month) }

  describe "#call" do
    context "with a month_to_month plan" do
      it "advances renews_at by one month" do
        sub = create(:subscription, subscription_plan: plan, renews_at: Date.new(2026, 4, 1))
        described_class.new(sub).call
        expect(sub.reload.renews_at).to eq(Date.new(2026, 5, 1))
      end

      it "sets status to active" do
        sub = create(:subscription, subscription_plan: plan, renews_at: Date.current, status: :lapsed)
        described_class.new(sub).call
        expect(sub.reload.status).to eq("active")
      end
    end

    context "with a monthly plan" do
      let(:plan) { create(:subscription_plan, subscription_type: :monthly) }

      it "does not change renews_at" do
        sub = create(:subscription, subscription_plan: plan, renews_at: Date.new(2026, 5, 1))
        described_class.new(sub).call
        expect(sub.reload.renews_at).to eq(Date.new(2026, 5, 1))
      end

      it "sets status to active" do
        sub = create(:subscription, subscription_plan: plan, renews_at: Date.current, status: :lapsed)
        described_class.new(sub).call
        expect(sub.reload.status).to eq("active")
      end
    end
  end
end
