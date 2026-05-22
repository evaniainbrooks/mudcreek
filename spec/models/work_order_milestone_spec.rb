require "rails_helper"

RSpec.describe WorkOrderMilestone, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order).tap { |wo| wo.update_columns(total_cents: 100_000) } }

  describe "associations" do
    it { is_expected.to belong_to(:work_order) }
    it { is_expected.to have_many(:invoices).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:trigger_state) }

    it "rejects a percentage below 1" do
      m = build(:work_order_milestone, work_order:, percentage: 0)
      expect(m).not_to be_valid
      expect(m.errors[:percentage]).to be_present
    end

    it "rejects a percentage above 100" do
      m = build(:work_order_milestone, work_order:, percentage: 101)
      expect(m).not_to be_valid
    end

    it "rejects an invalid trigger_state" do
      m = build(:work_order_milestone, work_order:, trigger_state: "nonexistent")
      expect(m).not_to be_valid
      expect(m.errors[:trigger_state]).to be_present
    end

    it "accepts any valid work order state as trigger_state" do
      WorkOrder.states.keys.each do |state|
        m = build(:work_order_milestone, work_order:, trigger_state: state, percentage: 10)
        expect(m).to be_valid, "expected #{state} to be valid"
      end
    end

    context "total percentage bounds" do
      it "prevents milestones that push the total above 100%" do
        create(:work_order_milestone, work_order:, percentage: 70, trigger_state: "contracted")
        overflow = build(:work_order_milestone, work_order:, percentage: 40, trigger_state: "completed")

        expect(overflow).not_to be_valid
        expect(overflow.errors[:percentage]).to be_present
      end

      it "allows milestones that sum exactly to 100%" do
        create(:work_order_milestone, work_order:, percentage: 60, trigger_state: "contracted")
        last = build(:work_order_milestone, work_order:, percentage: 40, trigger_state: "completed")

        expect(last).to be_valid
      end
    end
  end

  describe "monetization" do
    let(:milestone) { build(:work_order_milestone, work_order:, amount_cents: 25_000) }

    it "exposes amount as a Money object" do
      expect(milestone.amount).to be_a(Money)
      expect(milestone.amount.fractional).to eq(25_000)
    end
  end

  describe "#prospective_amount" do
    it "returns percentage of work order total as a Money object" do
      m = build(:work_order_milestone, work_order:, percentage: 10)
      result = m.prospective_amount(work_order)

      expect(result).to be_a(Money)
      expect(result.fractional).to eq(10_000)
    end

    it "rounds to the nearest cent" do
      wo = create(:work_order).tap { |w| w.update_columns(total_cents: 100_001) }
      m  = build(:work_order_milestone, work_order: wo, percentage: 33)

      result = m.prospective_amount(wo)
      expect(result.fractional).to eq(33_000)
    end
  end

  describe "#invoice_generated?" do
    it "defaults to false" do
      m = build(:work_order_milestone, work_order:)
      expect(m.invoice_generated?).to be false
    end
  end

  describe "ordering" do
    it "respects position via acts_as_list" do
      m2 = create(:work_order_milestone, work_order:, name: "Second", percentage: 50, trigger_state: "in_progress")
      m1 = create(:work_order_milestone, work_order:, name: "First",  percentage: 50, trigger_state: "contracted")
      m1.move_to_top

      expect(work_order.work_order_milestones.reload.map(&:name)).to eq(["First", "Second"])
    end
  end
end
