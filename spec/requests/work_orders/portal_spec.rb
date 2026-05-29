require "rails_helper"

RSpec.describe "WorkOrders::Portal", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:work_order) { create(:work_order, :contracted) }
  let(:valid_token) { work_order.client_upload_token }

  describe "GET /work_orders/:number/portal" do
    it "returns 200 with the correct token" do
      get portal_work_order_path(work_order, token: valid_token)

      expect(response).to have_http_status(:ok)
    end

    it "shows the work order title" do
      get portal_work_order_path(work_order, token: valid_token)

      expect(response.body).to include(work_order.title)
    end

    it "shows the work order number" do
      get portal_work_order_path(work_order, token: valid_token)

      expect(response.body).to include(work_order.number)
    end

    it "returns 404 with a wrong token" do
      get portal_work_order_path(work_order, token: "wrong")

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 with no token" do
      get portal_work_order_path(work_order)

      expect(response).to have_http_status(:not_found)
    end

    context "with line items" do
      let!(:work_order) { create(:work_order, :contracted, :with_items) }

      it "shows the line items" do
        get portal_work_order_path(work_order, token: valid_token)

        work_order.work_order_items.each do |item|
          expect(response.body).to include(item.name)
        end
      end
    end

    context "with milestones" do
      let!(:work_order) { create(:work_order, :contracted, :with_milestones) }

      it "shows the milestones" do
        get portal_work_order_path(work_order, token: valid_token)

        work_order.work_order_milestones.each do |ms|
          expect(response.body).to include(ms.name)
        end
      end
    end

    context "with a change order" do
      let!(:change_order) { create(:change_order, work_order: work_order) }

      it "shows the change order" do
        get portal_work_order_path(work_order, token: valid_token)

        expect(response.body).to include(change_order.number)
        expect(response.body).to include(change_order.description)
      end
    end

    context "with a client attachment" do
      before do
        work_order.client_attachments.attach(
          io: StringIO.new("data"), filename: "photo.jpg", content_type: "image/jpeg"
        )
      end

      it "shows the filename" do
        get portal_work_order_path(work_order, token: valid_token)

        expect(response.body).to include("photo.jpg")
      end
    end

    context "when unauthenticated (no session)" do
      it "still returns 200 — portal is public" do
        get portal_work_order_path(work_order, token: valid_token)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /work_orders/:number/portal (file upload)" do
    let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/receipt.pdf"), "application/pdf") }

    it "attaches the file with the correct token" do
      expect {
        post portal_work_order_path(work_order, token: valid_token), params: { files: [ file ] }
      }.to change { work_order.client_attachments.count }.by(1)
    end

    it "redirects back to the portal preserving the token" do
      post portal_work_order_path(work_order, token: valid_token), params: { files: [ file ] }

      expect(response).to redirect_to(portal_work_order_path(work_order, token: valid_token))
    end

    it "returns 404 with a wrong token" do
      post portal_work_order_path(work_order, token: "wrong"), params: { files: [ file ] }

      expect(response).to have_http_status(:not_found)
    end

    it "redirects cleanly with no files selected" do
      post portal_work_order_path(work_order, token: valid_token)

      expect(response).to redirect_to(portal_work_order_path(work_order, token: valid_token))
      expect(work_order.client_attachments.count).to eq(0)
    end
  end
end
