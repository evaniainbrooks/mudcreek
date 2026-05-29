require "rails_helper"

RSpec.describe "Admin::WorkOrders", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "work_order_manager", description: "Manage work orders").tap do |r|
      r.permissions.create!(resource: "WorkOrder", action: "index")
      r.permissions.create!(resource: "WorkOrder", action: "show")
      r.permissions.create!(resource: "WorkOrder", action: "create")
      r.permissions.create!(resource: "WorkOrder", action: "update")
      r.permissions.create!(resource: "WorkOrder", action: "destroy")
    end
  end

  let(:user)       { create(:user, role: role) }
  let!(:work_order) { create(:work_order) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/work_orders" do
    it "returns 200" do
      get admin_work_orders_path

      expect(response).to have_http_status(:ok)
    end

    it "lists work orders" do
      get admin_work_orders_path

      expect(response.body).to include(work_order.title)
    end

    context "Turbo Stream without page param" do
      it "renders the HTML index" do
        get admin_work_orders_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(work_order.title)
      end
    end

    context "ransack filtering by state" do
      let!(:contracted) { create(:work_order, :contracted) }

      it "returns only matching work orders" do
        get admin_work_orders_path, params: { q: { state_eq: "contracted" } }

        expect(response.body).to include(contracted.title)
        expect(response.body).not_to include(work_order.title)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_work_orders_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_work_orders_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/work_orders/:number" do
    it "returns 200" do
      get admin_work_order_path(work_order)

      expect(response).to have_http_status(:ok)
    end

    it "displays the work order title" do
      get admin_work_order_path(work_order)

      expect(response.body).to include(work_order.title)
    end

    context "with a guest work order" do
      let!(:work_order) { create(:work_order, client_name: "Bob Builder", client_email: "bob@build.example.com") }

      it "returns 200" do
        get admin_work_order_path(work_order)

        expect(response).to have_http_status(:ok)
      end

      it "displays the guest contact details" do
        get admin_work_order_path(work_order)

        expect(response.body).to include("Bob Builder")
        expect(response.body).to include("bob@build.example.com")
      end
    end

    context "with a user-linked work order" do
      let(:client) { create(:user) }
      let!(:work_order) { create(:work_order, :with_user, user: client) }

      it "returns 200" do
        get admin_work_order_path(work_order)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_work_order_path(work_order)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_work_order_path(work_order) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/work_orders/new" do
    it "returns 200" do
      get new_admin_work_order_path

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get new_admin_work_order_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /admin/work_orders" do
    let(:valid_params) do
      { work_order: { title: "Deck Repair", client_name: "Alice", client_email: "alice@example.com", client_phone: "555-1234", location_id: work_order.location_id } }
    end

    it "creates a work order and redirects to it" do
      post admin_work_orders_path, params: valid_params

      created = WorkOrder.find_by(title: "Deck Repair")
      expect(response).to redirect_to(admin_work_order_path(created))
    end

    it "increments work order count" do
      expect { post admin_work_orders_path, params: valid_params }
        .to change(WorkOrder, :count).by(1)
    end

    context "with a line item in the nested attributes" do
      let(:params_with_item) do
        valid_params.deep_merge(work_order: {
          work_order_items_attributes: { "0" => { name: "Lumber", quantity: 2, unit_price: "50.00" } }
        })
      end

      it "creates the work order item" do
        expect { post admin_work_orders_path, params: params_with_item }
          .to change(WorkOrderItem, :count).by(1)
      end

      it "associates the item with the new work order" do
        post admin_work_orders_path, params: params_with_item

        item = WorkOrder.find_by(title: "Deck Repair").work_order_items.first
        expect(item.name).to eq("Lumber")
        expect(item.quantity).to eq(2)
        expect(item.unit_price_cents).to eq(5_000)  # $50.00
      end
    end

    context "with a payment milestone in the nested attributes" do
      let(:params_with_milestone) do
        valid_params.deep_merge(work_order: {
          work_order_milestones_attributes: { "0" => { name: "Deposit", percentage: 50, trigger_state: "contracted" } }
        })
      end

      it "creates the work order milestone" do
        expect { post admin_work_orders_path, params: params_with_milestone }
          .to change(WorkOrderMilestone, :count).by(1)
      end

      it "associates the milestone with the new work order" do
        post admin_work_orders_path, params: params_with_milestone

        milestone = WorkOrder.find_by(title: "Deck Repair").work_order_milestones.first
        expect(milestone.name).to eq("Deposit")
        expect(milestone.percentage).to eq(50)
        expect(milestone.trigger_state).to eq("contracted")
      end
    end

    context "with a blank item row (unfilled template)" do
      let(:params_with_blank_item) do
        valid_params.deep_merge(work_order: {
          work_order_items_attributes: { "0" => { name: "", quantity: 1, unit_price: "" } }
        })
      end

      it "ignores the blank row and still creates the work order" do
        expect { post admin_work_orders_path, params: params_with_blank_item }
          .to change(WorkOrder, :count).by(1)
          .and change(WorkOrderItem, :count).by(0)
      end
    end

    context "with a blank milestone row (unfilled template)" do
      let(:params_with_blank_milestone) do
        valid_params.deep_merge(work_order: {
          work_order_milestones_attributes: { "0" => { name: "", percentage: "", trigger_state: "draft" } }
        })
      end

      it "ignores the blank row and still creates the work order" do
        expect { post admin_work_orders_path, params: params_with_blank_milestone }
          .to change(WorkOrder, :count).by(1)
          .and change(WorkOrderMilestone, :count).by(0)
      end
    end

    context "with invalid params" do
      it "returns 422" do
        post admin_work_orders_path, params: { work_order: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_work_orders_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "WorkOrder", action: "index")
          r.permissions.create!(resource: "WorkOrder", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_work_orders_path, params: valid_params }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/work_orders/:number/edit" do
    it "returns 200" do
      get edit_admin_work_order_path(work_order)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get edit_admin_work_order_path(work_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /admin/work_orders/:number" do
    it "updates the work order and redirects" do
      patch admin_work_order_path(work_order), params: { work_order: { title: "Updated Title" } }

      expect(work_order.reload.title).to eq("Updated Title")
      expect(response).to redirect_to(admin_work_order_path(work_order))
    end

    it "sets a flash notice" do
      patch admin_work_order_path(work_order), params: { work_order: { title: "New Title" } }

      expect(flash[:notice]).to be_present
    end

    context "with invalid params" do
      it "returns 422" do
        patch admin_work_order_path(work_order), params: { work_order: { title: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_work_order_path(work_order), params: { work_order: { title: "X" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "WorkOrder", action: "index")
          r.permissions.create!(resource: "WorkOrder", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { patch admin_work_order_path(work_order), params: { work_order: { title: "X" } } }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/work_orders/:number/send_estimate" do
    before do
      allow(WorkOrders::SendEstimateService).to receive(:call)
        .and_return(double(success?: true))
      allow(WorkOrders::SendSignatureRequestService).to receive(:call)
        .and_return(double(success?: true))
    end

    it "calls SendEstimateService with the work order" do
      post send_estimate_admin_work_order_path(work_order)

      expect(WorkOrders::SendEstimateService).to have_received(:call).with(work_order:)
    end

    it "calls SendSignatureRequestService when estimate succeeds" do
      post send_estimate_admin_work_order_path(work_order)

      expect(WorkOrders::SendSignatureRequestService).to have_received(:call).with(work_order:)
    end

    it "redirects with a notice on success" do
      post send_estimate_admin_work_order_path(work_order)

      expect(response).to redirect_to(admin_work_order_path(work_order))
      expect(flash[:notice]).to be_present
    end

    context "when SendEstimateService fails" do
      before do
        allow(WorkOrders::SendEstimateService).to receive(:call)
          .and_return(double(success?: false, error: "Estimate PDF not attached"))
      end

      it "redirects with an alert" do
        post send_estimate_admin_work_order_path(work_order)

        expect(response).to redirect_to(admin_work_order_path(work_order))
        expect(flash[:alert]).to eq("Estimate PDF not attached")
      end

      it "does not call SendSignatureRequestService" do
        post send_estimate_admin_work_order_path(work_order)

        expect(WorkOrders::SendSignatureRequestService).not_to have_received(:call)
      end
    end

    context "when SendSignatureRequestService fails" do
      before do
        allow(WorkOrders::SendSignatureRequestService).to receive(:call)
          .and_return(double(success?: false, error: "API key not configured"))
      end

      it "redirects with an alert" do
        post send_estimate_admin_work_order_path(work_order)

        expect(response).to redirect_to(admin_work_order_path(work_order))
        expect(flash[:alert]).to eq("API key not configured")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post send_estimate_admin_work_order_path(work_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "PATCH /admin/work_orders/:number/advance_state" do
    it "enqueues AdvanceWorkOrderStateJob with the new state" do
      expect { patch advance_state_admin_work_order_path(work_order), params: { state: "in_progress" } }
        .to have_enqueued_job(AdvanceWorkOrderStateJob).with(work_order.id, "in_progress")
    end

    it "redirects to the work order with a notice" do
      patch advance_state_admin_work_order_path(work_order), params: { state: "in_progress" }

      expect(response).to redirect_to(admin_work_order_path(work_order))
      expect(flash[:notice]).to be_present
    end

    context "with an invalid state" do
      it "redirects with an alert and does not enqueue a job" do
        expect { patch advance_state_admin_work_order_path(work_order), params: { state: "invalid" } }
          .not_to have_enqueued_job(AdvanceWorkOrderStateJob)

        expect(response).to redirect_to(admin_work_order_path(work_order))
        expect(flash[:alert]).to be_present
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch advance_state_admin_work_order_path(work_order), params: { state: "in_progress" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/work_orders/:number/estimate" do
    it "returns 200 without a layout" do
      get estimate_admin_work_order_path(work_order)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get estimate_admin_work_order_path(work_order)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
