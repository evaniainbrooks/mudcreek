require "rails_helper"

RSpec.describe HandleDropboxSignEventJob, type: :job do
  before { Current.tenant = create(:tenant, default: true) }
  after  { Current.tenant = nil }

  let(:work_order) do
    create(:work_order, dropbox_sign_request_id: "req-abc-123")
  end

  def event_for(request_id)
    { "signature_request" => { "signature_request_id" => request_id } }
  end

  def perform(event)
    described_class.new.perform(event)
  end

  describe "when the event has no signature_request_id" do
    it "does not enqueue ProcessWorkOrderContractJob" do
      expect { perform({}) }
        .not_to have_enqueued_job(ProcessWorkOrderContractJob)
    end

    it "does not enqueue ProcessWorkOrderContractJob when key is blank" do
      expect { perform("signature_request" => { "signature_request_id" => "" }) }
        .not_to have_enqueued_job(ProcessWorkOrderContractJob)
    end
  end

  describe "when no work order matches the request_id" do
    it "does not enqueue ProcessWorkOrderContractJob" do
      expect { perform(event_for("unknown-request-id")) }
        .not_to have_enqueued_job(ProcessWorkOrderContractJob)
    end
  end

  describe "when a matching work order exists" do
    it "enqueues ProcessWorkOrderContractJob with the work order id" do
      expect { perform(event_for(work_order.dropbox_sign_request_id)) }
        .to have_enqueued_job(ProcessWorkOrderContractJob).with(work_order.id)
    end

    it "sets Current.tenant from the work order" do
      work_order  # force creation while tenant is set
      Current.tenant = nil

      perform(event_for(work_order.dropbox_sign_request_id))

      expect(Current.tenant).to eq(work_order.tenant)
    end
  end
end
