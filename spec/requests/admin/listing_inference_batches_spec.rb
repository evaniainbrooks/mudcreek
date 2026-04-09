require "rails_helper"

RSpec.describe "Admin::ListingInferenceBatches", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "batch_manager", description: "Manage batches").tap do |r|
      r.permissions.create!(resource: "ListingInferenceBatch", action: "show")
      r.permissions.create!(resource: "ListingInferenceBatch", action: "create")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:lot)  { create(:lot) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/listing_inference_batches/new" do
    it "returns 200" do
      get new_admin_listing_inference_batch_path

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get new_admin_listing_inference_batch_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/listing_inference_batches" do
    before { allow(ProcessListingInferenceBatchJob).to receive(:perform_later) }

    let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.jpg"), "image/jpeg") }

    it "creates a batch, enqueues the job, and redirects to show" do
      expect {
        post admin_listing_inference_batches_path,
          params: { listing_inference_batch: { lot_id: lot.id, source_files: [file] } }
      }.to change(ListingInferenceBatch, :count).by(1)

      expect(ProcessListingInferenceBatchJob).to have_received(:perform_later)
      expect(response).to redirect_to(admin_listing_inference_batch_path(ListingInferenceBatch.last))
    end

    it "re-renders new with unprocessable_content when no files" do
      post admin_listing_inference_batches_path,
        params: { listing_inference_batch: { lot_id: lot.id } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_listing_inference_batches_path,
          params: { listing_inference_batch: { lot_id: lot.id } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/listing_inference_batches/:hashid" do
    let!(:batch) do
      b = ListingInferenceBatch.new(lot: lot, status: "pending", tenant: Current.tenant)
      b.source_files.attach(io: StringIO.new("data"), filename: "file.jpg", content_type: "image/jpeg")
      b.save!
      b
    end

    it "returns 200" do
      get admin_listing_inference_batch_path(batch)

      expect(response).to have_http_status(:ok)
    end
  end
end
