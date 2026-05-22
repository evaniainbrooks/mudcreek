require "rails_helper"

RSpec.describe "Webhooks::DropboxSign", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:api_key) { "test_dropbox_sign_key" }

  before do
    allow(Rails.application.credentials).to receive(:dropbox_sign)
      .and_return(double(api_key: api_key))
  end

  def signed_event(event_type: "signature_request_signed")
    { "event" => { "event_type" => event_type, "event_hash" => "placeholder" } }
  end

  def post_webhook(event)
    allow_any_instance_of(Webhooks::DropboxSignController)
      .to receive(:valid_signature?).and_return(true)

    post webhooks_dropbox_sign_path, params: { json: event.to_json }
  end

  def post_webhook_unsigned(event)
    post webhooks_dropbox_sign_path, params: { json: event.to_json }
  end

  describe "POST /webhooks/dropbox_sign" do
    context "with an invalid signature" do
      it "returns 401" do
        post webhooks_dropbox_sign_path,
          params: { json: { "event" => { "event_type" => "signature_request_signed", "event_hash" => "badsig" } }.to_json }

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not enqueue HandleDropboxSignEventJob" do
        expect {
          post webhooks_dropbox_sign_path,
            params: { json: { "event" => { "event_type" => "signature_request_signed", "event_hash" => "badsig" } }.to_json }
        }.not_to have_enqueued_job(HandleDropboxSignEventJob)
      end
    end

    context "when the API key is not configured" do
      before do
        allow(Rails.application.credentials).to receive(:dropbox_sign).and_return(nil)
      end

      it "returns 401" do
        post webhooks_dropbox_sign_path,
          params: { json: { "event" => { "event_type" => "signature_request_signed", "event_hash" => "any" } }.to_json }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the event_hash is missing" do
      it "returns 401" do
        post webhooks_dropbox_sign_path,
          params: { json: { "event" => { "event_type" => "signature_request_signed" } }.to_json }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid signature and signature_request_signed event" do
      it "returns 200" do
        post_webhook(signed_event)

        expect(response).to have_http_status(:ok)
      end

      it "responds with the required Dropbox Sign acknowledgement body" do
        post_webhook(signed_event)

        expect(response.body).to eq("Hello API Event Received")
      end

      it "enqueues HandleDropboxSignEventJob" do
        expect { post_webhook(signed_event) }
          .to have_enqueued_job(HandleDropboxSignEventJob)
      end
    end

    context "with a valid signature and a non-signing event type" do
      it "does not enqueue HandleDropboxSignEventJob" do
        expect { post_webhook(signed_event(event_type: "signature_request_viewed")) }
          .not_to have_enqueued_job(HandleDropboxSignEventJob)
      end

      it "returns 200" do
        post_webhook(signed_event(event_type: "signature_request_viewed"))

        expect(response).to have_http_status(:ok)
      end

      it "still responds with the required acknowledgement body" do
        post_webhook(signed_event(event_type: "signature_request_viewed"))

        expect(response.body).to eq("Hello API Event Received")
      end
    end
  end
end
