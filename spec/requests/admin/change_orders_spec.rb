require "rails_helper"

RSpec.describe "Admin::ChangeOrders", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "change_order_manager", description: "Manage change orders").tap do |r|
      r.permissions.create!(resource: "WorkOrder",    action: "show")
      r.permissions.create!(resource: "ChangeOrder",  action: "create")
      r.permissions.create!(resource: "ChangeOrder",  action: "show")
      r.permissions.create!(resource: "ChangeOrder",  action: "update")
      r.permissions.create!(resource: "ChangeOrder",  action: "destroy")
    end
  end

  let(:user)         { create(:user, role: role) }
  let!(:work_order)  { create(:work_order, :contracted) }
  let!(:change_order) { create(:change_order, work_order: work_order) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/work_orders/:work_order_number/change_orders/new" do
    it "returns 200" do
      get new_admin_work_order_change_order_path(work_order)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        get new_admin_work_order_change_order_path(work_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /admin/work_orders/:work_order_number/change_orders" do
    let(:valid_params) do
      { change_order: { description: "Add extra insulation", amount: "250.00" } }
    end

    it "creates the change order" do
      expect { post admin_work_order_change_orders_path(work_order), params: valid_params }
        .to change(ChangeOrder, :count).by(1)
    end

    it "redirects to the change order show page" do
      post admin_work_order_change_orders_path(work_order), params: valid_params

      created = ChangeOrder.find_by(description: "Add extra insulation")
      expect(response).to redirect_to(admin_work_order_change_order_path(work_order, created))
    end

    it "stores the amount in cents" do
      post admin_work_order_change_orders_path(work_order), params: valid_params

      expect(ChangeOrder.find_by(description: "Add extra insulation").amount_cents).to eq(25_000)
    end

    it "defaults to draft status" do
      post admin_work_order_change_orders_path(work_order), params: valid_params

      expect(ChangeOrder.find_by(description: "Add extra insulation").status).to eq("draft")
    end

    context "with invalid params" do
      it "returns 422" do
        post admin_work_order_change_orders_path(work_order),
          params: { change_order: { description: "", amount: "100.00" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a change order" do
        expect {
          post admin_work_order_change_orders_path(work_order),
            params: { change_order: { description: "", amount: "100.00" } }
        }.not_to change(ChangeOrder, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        post admin_work_order_change_orders_path(work_order), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_work_order_change_orders_path(work_order), params: valid_params }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/work_orders/:work_order_number/change_orders/:number" do
    it "returns 200" do
      get admin_work_order_change_order_path(work_order, change_order)

      expect(response).to have_http_status(:ok)
    end

    it "displays the change order number" do
      get admin_work_order_change_order_path(work_order, change_order)

      expect(response.body).to include(change_order.number)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        get admin_work_order_change_order_path(work_order, change_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /admin/work_orders/:work_order_number/change_orders/:number/send_for_signature" do
    before do
      allow(WorkOrders::SendChangeOrderService).to receive(:call)
        .and_return(double(success?: true))
    end

    it "calls SendChangeOrderService with the change order" do
      post send_for_signature_admin_work_order_change_order_path(work_order, change_order)

      expect(WorkOrders::SendChangeOrderService).to have_received(:call).with(change_order:)
    end

    it "redirects to the change order show page with a notice" do
      post send_for_signature_admin_work_order_change_order_path(work_order, change_order)

      expect(response).to redirect_to(admin_work_order_change_order_path(work_order, change_order))
      expect(flash[:notice]).to be_present
    end

    context "when SendChangeOrderService fails" do
      before do
        allow(WorkOrders::SendChangeOrderService).to receive(:call)
          .and_return(double(success?: false, error: "API key not configured"))
      end

      it "redirects with an alert" do
        post send_for_signature_admin_work_order_change_order_path(work_order, change_order)

        expect(response).to redirect_to(admin_work_order_change_order_path(work_order, change_order))
        expect(flash[:alert]).to eq("API key not configured")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        post send_for_signature_admin_work_order_change_order_path(work_order, change_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
