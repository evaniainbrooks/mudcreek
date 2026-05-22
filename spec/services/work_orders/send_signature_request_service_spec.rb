require "rails_helper"

RSpec.describe WorkOrders::SendSignatureRequestService do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:work_order) { create(:work_order, :estimate_sent) }
  let(:request_id) { "abc123-sig-request-id" }

  def stub_dropbox_sign(request_id:)
    signature_request = double("signature_request", signature_request_id: request_id)
    response          = double("response", signature_request:)
    api               = instance_double(Dropbox::Sign::SignatureRequestApi, signature_request_send: response)

    allow(Dropbox::Sign::SignatureRequestApi).to receive(:new).and_return(api)
    allow(Dropbox::Sign::ApiClient).to receive(:new).and_return(double("api_client"))
    allow(Dropbox::Sign::Configuration).to receive(:new).and_return(double("config", username: nil, "username=": nil))

    api
  end

  def attach_estimate_pdf(work_order)
    work_order.estimate_pdf.attach(
      io:           StringIO.new("fake pdf content"),
      filename:     "estimate.pdf",
      content_type: "application/pdf"
    )
  end

  before do
    allow(Rails.application.credentials).to receive(:dropbox_sign).and_return(
      double("creds", api_key: "test-api-key")
    )
    attach_estimate_pdf(work_order)
  end

  describe ".call" do
    context "when credentials and PDF are present" do
      before { stub_dropbox_sign(request_id:) }

      it "returns a successful result" do
        result = described_class.call(work_order:)
        expect(result).to be_success
      end

      it "stores the dropbox_sign_request_id on the work order" do
        described_class.call(work_order:)
        expect(work_order.reload.dropbox_sign_request_id).to eq(request_id)
      end

      it "sends the signature request with the correct signer" do
        api = stub_dropbox_sign(request_id:)

        described_class.call(work_order:)

        expect(api).to have_received(:signature_request_send) do |request|
          signer = request.signers.first
          expect(signer.email_address).to eq(work_order.client_contact_email)
          expect(signer.name).to eq(work_order.client_display_name)
        end
      end
    end

    context "when Dropbox Sign API key is not configured" do
      before do
        allow(Rails.application.credentials).to receive(:dropbox_sign).and_return(nil)
      end

      it "returns a failure result without calling the API" do
        expect(Dropbox::Sign::SignatureRequestApi).not_to receive(:new)
        result = described_class.call(work_order:)
        expect(result).not_to be_success
        expect(result.error).to match(/not configured/i)
      end
    end

    context "when estimate PDF is not attached" do
      before { work_order.estimate_pdf.purge }

      it "returns a failure result" do
        result = described_class.call(work_order:)
        expect(result).not_to be_success
        expect(result.error).to match(/PDF not attached/i)
      end
    end

    context "when the Dropbox Sign API returns an error" do
      before do
        stub_dropbox_sign(request_id:)
        api = instance_double(Dropbox::Sign::SignatureRequestApi)
        allow(Dropbox::Sign::SignatureRequestApi).to receive(:new).and_return(api)
        allow(api).to receive(:signature_request_send).and_raise(
          Dropbox::Sign::ApiError, "Unauthorized"
        )
      end

      it "returns a failure result" do
        result = described_class.call(work_order:)
        expect(result).not_to be_success
        expect(result.error).to be_present
      end
    end
  end
end
