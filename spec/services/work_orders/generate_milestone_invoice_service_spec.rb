require "rails_helper"

RSpec.describe WorkOrders::GenerateMilestoneInvoiceService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order).tap { |wo| wo.update_columns(total_cents: 100_000) } }
  let(:milestone) do
    create(:work_order_milestone, work_order:, name: "Deposit", percentage: 10,
           trigger_state: "contracted", amount_cents: 10_000)
  end

  before { allow(WorkOrderMailer).to receive_message_chain(:milestone_invoice, :deliver_later) }

  describe ".call" do
    context "when the invoice has not been generated yet" do
      it "returns a successful result" do
        result = described_class.call(milestone:)
        expect(result).to be_success
        expect(result.invoice).to be_a(Invoice)
      end

      it "creates an Invoice with the milestone amount" do
        expect { described_class.call(milestone:) }.to change(Invoice, :count).by(1)
        expect(Invoice.last.total_cents).to eq(10_000)
      end

      it "creates an InvoiceItem for the milestone" do
        described_class.call(milestone:)
        item = Invoice.last.invoice_items.first
        expect(item.name).to eq("Deposit")
        expect(item.amount_cents).to eq(10_000)
      end

      it "links the invoice back to the milestone" do
        described_class.call(milestone:)
        expect(Invoice.last.work_order_milestone).to eq(milestone)
      end

      it "marks the milestone as invoice_generated" do
        described_class.call(milestone:)
        expect(milestone.reload.invoice_generated).to be true
      end

      it "delivers the milestone invoice mailer" do
        mail_double = double("mail", deliver_later: true)
        allow(WorkOrderMailer).to receive(:milestone_invoice).and_return(mail_double)

        described_class.call(milestone:)

        expect(WorkOrderMailer).to have_received(:milestone_invoice).with(instance_of(Invoice))
        expect(mail_double).to have_received(:deliver_later)
      end

      context "with a linked user" do
        let(:user) { create(:user) }
        let(:work_order) { create(:work_order, :with_user, user:, total_cents: 100_000) }

        it "sets the invoice user to the work order user" do
          described_class.call(milestone:)
          expect(Invoice.last.user).to eq(user)
        end
      end

      context "with a guest work order (no user)" do
        it "creates an invoice with a nil user" do
          described_class.call(milestone:)
          expect(Invoice.last.user).to be_nil
        end
      end
    end

    context "when the invoice has already been generated" do
      before { milestone.update_columns(invoice_generated: true) }

      it "returns a failure result" do
        result = described_class.call(milestone:)
        expect(result).not_to be_success
        expect(result.error).to be_present
      end

      it "does not create another invoice" do
        expect { described_class.call(milestone:) }.not_to change(Invoice, :count)
      end
    end
  end
end
