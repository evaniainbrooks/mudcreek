require "rails_helper"

RSpec.describe ProcessWorkOrderContractJob, type: :job do
  before { Current.tenant = create(:tenant, default: true) }
  after  { Current.tenant = nil }

  let(:work_order) do
    create(:work_order, :estimate_sent).tap { |wo| wo.update_columns(total_cents: 100_000) }
  end

  def perform
    described_class.new.perform(work_order.id)
  end

  describe "tenant setup" do
    it "sets Current.tenant from the work order before acting" do
      id = work_order.id
      Current.tenant = nil

      expect { described_class.new.perform(id) }
        .to change { work_order.reload.state }.to("contracted")
    end
  end

  describe "state transition" do
    it "transitions the work order to contracted" do
      perform
      expect(work_order.reload.state).to eq("contracted")
    end

    it "records contracted_at" do
      freeze_time do
        perform
        expect(work_order.reload.contracted_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "milestone amount computation" do
    it "delegates to ComputeMilestoneAmountsService before updating state" do
      called_before_contracted = false

      allow(WorkOrders::ComputeMilestoneAmountsService).to receive(:call) do |kwargs|
        called_before_contracted = kwargs[:work_order].reload.state != "contracted"
      end

      perform

      expect(called_before_contracted).to be true
    end

    it "calls ComputeMilestoneAmountsService with the work order" do
      allow(WorkOrders::ComputeMilestoneAmountsService).to receive(:call)
      perform
      expect(WorkOrders::ComputeMilestoneAmountsService).to have_received(:call)
        .with(work_order:)
    end
  end

  describe "milestone invoice generation" do
    let!(:contracted_milestone) do
      create(:work_order_milestone, work_order:, trigger_state: "contracted",
             percentage: 10, amount_cents: 10_000, invoice_generated: false)
    end

    let!(:other_milestone) do
      create(:work_order_milestone, work_order:, trigger_state: "completed",
             percentage: 80, amount_cents: 80_000, invoice_generated: false)
    end

    before { allow(WorkOrders::GenerateMilestoneInvoiceService).to receive(:call) }

    it "generates invoices only for milestones with trigger_state 'contracted'" do
      perform
      expect(WorkOrders::GenerateMilestoneInvoiceService).to have_received(:call)
        .with(milestone: contracted_milestone)
      expect(WorkOrders::GenerateMilestoneInvoiceService).not_to have_received(:call)
        .with(milestone: other_milestone)
    end

    it "skips milestones that already have an invoice generated" do
      contracted_milestone.update_columns(invoice_generated: true)
      perform
      expect(WorkOrders::GenerateMilestoneInvoiceService).not_to have_received(:call)
    end

    it "generates invoices for all uninvoiced contracted milestones" do
      extra = create(:work_order_milestone, work_order:, trigger_state: "contracted",
                     percentage: 5, amount_cents: 5_000, invoice_generated: false)
      perform
      expect(WorkOrders::GenerateMilestoneInvoiceService).to have_received(:call).twice
    end
  end

  describe "admin notification" do
    it "delivers the contract_signed mailer" do
      expect { perform }
        .to have_enqueued_mail(WorkOrderMailer, :contract_signed).with(work_order)
    end
  end
end
