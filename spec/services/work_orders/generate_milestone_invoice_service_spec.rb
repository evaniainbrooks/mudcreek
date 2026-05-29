require "rails_helper"

RSpec.describe WorkOrders::GenerateMilestoneInvoiceService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:location) { create(:location, tax_rate: 0.10) }
  let(:work_order) do
    create(:work_order, location:).tap do |wo|
      create(:work_order_item, work_order: wo, name: "Labour",   quantity: 1, unit_price_cents: 80_000, tax_exempt: false)
      create(:work_order_item, work_order: wo, name: "Permit",   quantity: 1, unit_price_cents: 20_000, tax_exempt: true)
      wo.update_columns(total_cents: 100_000)
    end
  end
  # 10% milestone → amount_cents = 10_000
  # Labour portion: 8_000, Permit portion: 2_000 (exempt)
  # Tax: 8_000 * 0.10 = 800
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

      it "creates one invoice" do
        expect { described_class.call(milestone:) }.to change(Invoice, :count).by(1)
      end

      it "creates invoice items for each work order item" do
        described_class.call(milestone:)
        items = Invoice.last.invoice_items.order(:id)
        expect(items.map(&:name)).to include("Labour", "Permit")
        expect(items.find { |i| i.name == "Labour" }.amount_cents).to eq(8_000)
        expect(items.find { |i| i.name == "Permit" }.amount_cents).to eq(2_000)
      end

      it "appends a tax line item for the taxable portion" do
        described_class.call(milestone:)
        tax_item = Invoice.last.invoice_items.find { |i| i.name.start_with?("Tax") }
        expect(tax_item).to be_present
        expect(tax_item.amount_cents).to eq(800)
      end

      it "sets the invoice total to milestone amount plus tax" do
        described_class.call(milestone:)
        expect(Invoice.last.total_cents).to eq(10_800)
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

      context "when all items are tax exempt" do
        before do
          work_order.work_order_items.update_all(tax_exempt: true)
        end

        it "does not add a tax line item" do
          described_class.call(milestone:)
          tax_item = Invoice.last.invoice_items.find { |i| i.name.start_with?("Tax") }
          expect(tax_item).to be_nil
        end

        it "sets the invoice total to just the milestone amount" do
          described_class.call(milestone:)
          expect(Invoice.last.total_cents).to eq(10_000)
        end
      end

      context "when the location has no tax rate" do
        let(:location) { create(:location, tax_rate: 0) }

        it "does not add a tax line item" do
          described_class.call(milestone:)
          tax_item = Invoice.last.invoice_items.find { |i| i.name.start_with?("Tax") }
          expect(tax_item).to be_nil
        end

        it "sets the invoice total to just the milestone amount" do
          described_class.call(milestone:)
          expect(Invoice.last.total_cents).to eq(10_000)
        end
      end

      context "with a linked user" do
        let(:user) { create(:user) }
        let(:work_order) do
          create(:work_order, :with_user, user:, location:).tap do |wo|
            create(:work_order_item, work_order: wo, quantity: 1, unit_price_cents: 100_000)
            wo.update_columns(total_cents: 100_000)
          end
        end

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
