require "rails_helper"

RSpec.describe WorkOrders::ComputeMilestoneAmountsService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe ".call" do
    let(:work_order) { create(:work_order).tap { |wo| wo.update_columns(total_cents: 100_000) } }

    it "sets amount_cents on each milestone proportionally" do
      deposit    = create(:work_order_milestone, work_order:, percentage: 10, trigger_state: "contracted")
      midway     = create(:work_order_milestone, work_order:, percentage: 40, trigger_state: "in_progress")
      completion = create(:work_order_milestone, work_order:, percentage: 50, trigger_state: "completed")

      described_class.call(work_order:)

      expect(deposit.reload.amount_cents).to eq(10_000)
      expect(midway.reload.amount_cents).to eq(40_000)
      expect(completion.reload.amount_cents).to eq(50_000)
    end

    it "rounds to the nearest cent" do
      wo = create(:work_order).tap { |w| w.update_columns(total_cents: 100_001) }
      m  = create(:work_order_milestone, work_order: wo, percentage: 33, trigger_state: "contracted")

      described_class.call(work_order: wo)

      expect(m.reload.amount_cents).to eq(33_000)
    end

    it "does not affect invoice_generated flag" do
      m = create(:work_order_milestone, work_order:, percentage: 100, trigger_state: "contracted",
                 invoice_generated: false)
      described_class.call(work_order:)
      expect(m.reload.invoice_generated).to be false
    end
  end
end
