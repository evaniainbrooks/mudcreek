require "rails_helper"

RSpec.describe "Admin::WorkOrderItems", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "item_manager", description: "Manage work order items").tap do |r|
      r.permissions.create!(resource: "WorkOrderItem", action: "create")
      r.permissions.create!(resource: "WorkOrderItem", action: "update")
      r.permissions.create!(resource: "WorkOrderItem", action: "destroy")
    end
  end

  let(:user)       { create(:user, role: role) }
  let!(:work_order) { create(:work_order) }
  let!(:item)       { create(:work_order_item, work_order: work_order) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  let(:valid_params) do
    { work_order_item: { name: "Labor", quantity: 3, unit_price_cents: 12_000 } }
  end

  describe "POST /admin/work_orders/:work_order_number/work_order_items" do
    it "creates an item and returns a Turbo Stream response" do
      expect { post admin_work_order_work_order_items_path(work_order), params: valid_params }
        .to change { work_order.work_order_items.count }.by(1)
    end

    it "returns 200" do
      post admin_work_order_work_order_items_path(work_order), params: valid_params

      expect(response).to have_http_status(:ok)
    end

    it "includes the item name in the Turbo Stream response" do
      post admin_work_order_work_order_items_path(work_order), params: valid_params

      expect(response.body).to include("Labor")
    end

    context "with invalid params" do
      it "returns 422" do
        post admin_work_order_work_order_items_path(work_order),
          params: { work_order_item: { name: "", quantity: 1, unit_price_cents: 0 } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create an item" do
        expect {
          post admin_work_order_work_order_items_path(work_order),
            params: { work_order_item: { name: "", quantity: 1, unit_price_cents: 0 } }
        }.not_to change { work_order.work_order_items.count }
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_work_order_work_order_items_path(work_order), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_work_order_work_order_items_path(work_order), params: valid_params }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/work_orders/:work_order_number/work_order_items/:id" do
    it "updates the item and returns 200" do
      patch admin_work_order_work_order_item_path(work_order, item),
        params: { work_order_item: { name: "Updated Labor" } }

      expect(item.reload.name).to eq("Updated Labor")
      expect(response).to have_http_status(:ok)
    end

    context "with invalid params" do
      it "returns 422" do
        patch admin_work_order_work_order_item_path(work_order, item),
          params: { work_order_item: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_work_order_work_order_item_path(work_order, item),
          params: { work_order_item: { name: "X" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "create_only", description: "Create only").tap do |r|
          r.permissions.create!(resource: "WorkOrderItem", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_work_order_work_order_item_path(work_order, item),
            params: { work_order_item: { name: "X" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/work_orders/:work_order_number/work_order_items/:id" do
    it "destroys the item and returns 200" do
      expect { delete admin_work_order_work_order_item_path(work_order, item) }
        .to change { work_order.work_order_items.count }.by(-1)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_work_order_work_order_item_path(work_order, item)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "no_destroy", description: "No destroy").tap do |r|
          r.permissions.create!(resource: "WorkOrderItem", action: "create")
          r.permissions.create!(resource: "WorkOrderItem", action: "update")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { delete admin_work_order_work_order_item_path(work_order, item) }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
