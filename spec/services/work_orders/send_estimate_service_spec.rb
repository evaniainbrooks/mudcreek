require "rails_helper"

RSpec.describe WorkOrders::SendEstimateService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order, :with_items) }
  let(:fake_pdf)   { "%PDF-1.4 fake content" }

  before do
    grover_double = instance_double(Grover, to_pdf: fake_pdf)
    allow(Grover).to receive(:new).and_return(grover_double)

    allow(ApplicationController.renderer).to receive(:render).and_return("<html>estimate</html>")

    mailer_double = double("mailer", deliver_later: true)
    allow(WorkOrderMailer).to receive(:estimate_email).and_return(mailer_double)
  end

  describe ".call" do
    it "returns a successful result" do
      result = described_class.call(work_order:)
      expect(result).to be_success
    end

    it "attaches the generated PDF to the work order" do
      described_class.call(work_order:)
      expect(work_order.estimate_pdf).to be_attached
    end

    it "attaches the PDF with the correct filename" do
      described_class.call(work_order:)
      expect(work_order.estimate_pdf.filename.to_s).to eq("estimate-#{work_order.number}.pdf")
    end

    it "transitions state to estimate_sent" do
      described_class.call(work_order:)
      expect(work_order.reload.state).to eq("estimate_sent")
    end

    it "records estimate_sent_at" do
      freeze_time do
        described_class.call(work_order:)
        expect(work_order.reload.estimate_sent_at).to be_within(1.second).of(Time.current)
      end
    end

    it "enqueues the estimate email" do
      mailer_double = double("mailer", deliver_later: true)
      allow(WorkOrderMailer).to receive(:estimate_email).with(work_order).and_return(mailer_double)

      described_class.call(work_order:)

      expect(mailer_double).to have_received(:deliver_later)
    end

    it "renders the estimate template via ApplicationController renderer" do
      described_class.call(work_order:)
      expect(ApplicationController.renderer).to have_received(:render).with(
        hash_including(template: "work_orders/estimate", layout: false)
      )
    end

    context "when Grover raises an error" do
      before do
        allow(Grover).to receive(:new).and_raise(Grover::JavaScript::Error, "Chrome crashed")
      end

      it "returns a failure result" do
        result = described_class.call(work_order:)
        expect(result).not_to be_success
        expect(result.error).to match(/Chrome crashed/)
      end

      it "does not change the work order state" do
        described_class.call(work_order:)
        expect(work_order.reload.state).to eq("draft")
      end
    end
  end
end
