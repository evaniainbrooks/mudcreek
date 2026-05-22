require "rails_helper"

RSpec.describe "WorkOrders", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:work_order) { create(:work_order) }

  describe "GET /work_orders/:number/signed" do
    it "returns 200 without requiring authentication" do
      get signed_work_order_path(work_order)

      expect(response).to have_http_status(:ok)
    end

    it "displays the work order title" do
      get signed_work_order_path(work_order)

      expect(response.body).to include(work_order.title)
    end

    context "with a non-existent work order number" do
      it "returns 404" do
        get signed_work_order_path("WO-NONEXISTENT")

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
