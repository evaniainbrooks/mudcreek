require "rails_helper"

RSpec.describe AdvanceWorkOrderStateJob, type: :job do
  before { Current.tenant = create(:tenant, default: true) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order, :contracted) }

  def perform(state)
    described_class.new.perform(work_order.id, state)
  end

  describe "tenant setup" do
    it "sets Current.tenant from the work order before acting" do
      id = work_order.id
      Current.tenant = nil

      expect { described_class.new.perform(id, "in_progress") }
        .to change { work_order.reload.state }.to("in_progress")
    end
  end

  describe "state transition" do
    it "updates the work order to the given state" do
      perform("in_progress")
      expect(work_order.reload.state).to eq("in_progress")
    end

    it "accepts any valid work order state" do
      perform("cancelled")
      expect(work_order.reload.state).to eq("cancelled")
    end
  end

  describe "completed_at timestamp" do
    it "records completed_at when advancing to completed" do
      freeze_time do
        perform("completed")
        expect(work_order.reload.completed_at).to be_within(1.second).of(Time.current)
      end
    end

    it "does not set completed_at for other states" do
      perform("in_progress")
      expect(work_order.reload.completed_at).to be_nil
    end
  end

  describe "milestone invoice generation" do
    let!(:matching_milestone) do
      create(:work_order_milestone, work_order:, trigger_state: "in_progress",
             percentage: 40, amount_cents: 40_000, invoice_generated: false)
    end

    let!(:other_milestone) do
      create(:work_order_milestone, work_order:, trigger_state: "completed",
             percentage: 50, amount_cents: 50_000, invoice_generated: false)
    end

    before do
      allow(WorkOrders::GenerateMilestoneInvoiceService).to receive(:call)
    end

    it "calls GenerateMilestoneInvoiceService for milestones matching the new state" do
      perform("in_progress")
      expect(WorkOrders::GenerateMilestoneInvoiceService).to have_received(:call)
        .with(milestone: matching_milestone)
    end

    it "does not call the service for milestones with a different trigger_state" do
      perform("in_progress")
      expect(WorkOrders::GenerateMilestoneInvoiceService).not_to have_received(:call)
        .with(milestone: other_milestone)
    end

    it "skips milestones that already have an invoice generated" do
      matching_milestone.update_columns(invoice_generated: true)
      perform("in_progress")
      expect(WorkOrders::GenerateMilestoneInvoiceService).not_to have_received(:call)
    end

    it "generates invoices for all matching milestones" do
      extra = create(:work_order_milestone, work_order:, trigger_state: "in_progress",
                     percentage: 10, amount_cents: 10_000, invoice_generated: false)
      perform("in_progress")
      expect(WorkOrders::GenerateMilestoneInvoiceService).to have_received(:call).twice
    end
  end
end
