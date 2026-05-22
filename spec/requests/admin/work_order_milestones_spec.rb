require "rails_helper"

RSpec.describe "Admin::WorkOrderMilestones", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "milestone_manager", description: "Manage work order milestones").tap do |r|
      r.permissions.create!(resource: "WorkOrderMilestone", action: "create")
      r.permissions.create!(resource: "WorkOrderMilestone", action: "update")
      r.permissions.create!(resource: "WorkOrderMilestone", action: "destroy")
    end
  end

  let(:user)       { create(:user, role: role) }
  let!(:work_order) { create(:work_order) }
  let!(:milestone)  { create(:work_order_milestone, work_order: work_order, percentage: 50) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  let(:valid_params) do
    { work_order_milestone: { name: "Completion", percentage: 50, trigger_state: "completed" } }
  end

  describe "POST /admin/work_orders/:work_order_number/work_order_milestones" do
    it "creates a milestone and returns 200" do
      expect { post admin_work_order_work_order_milestones_path(work_order), params: valid_params }
        .to change { work_order.work_order_milestones.count }.by(1)
    end

    it "returns 200" do
      post admin_work_order_work_order_milestones_path(work_order), params: valid_params

      expect(response).to have_http_status(:ok)
    end

    it "includes the milestone name in the Turbo Stream response" do
      post admin_work_order_work_order_milestones_path(work_order), params: valid_params

      expect(response.body).to include("Completion")
    end

    context "with invalid params (missing name)" do
      it "returns 422" do
        post admin_work_order_work_order_milestones_path(work_order),
          params: { work_order_milestone: { name: "", percentage: 50, trigger_state: "contracted" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a milestone" do
        expect {
          post admin_work_order_work_order_milestones_path(work_order),
            params: { work_order_milestone: { name: "", percentage: 50, trigger_state: "contracted" } }
        }.not_to change { work_order.work_order_milestones.count }
      end
    end

    context "when the total percentage would exceed 100" do
      it "returns 422" do
        post admin_work_order_work_order_milestones_path(work_order),
          params: { work_order_milestone: { name: "Over limit", percentage: 60, trigger_state: "completed" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_work_order_work_order_milestones_path(work_order), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_work_order_work_order_milestones_path(work_order), params: valid_params }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/work_orders/:work_order_number/work_order_milestones/:id" do
    it "updates the milestone and returns 200" do
      patch admin_work_order_work_order_milestone_path(work_order, milestone),
        params: { work_order_milestone: { name: "Updated Milestone" } }

      expect(milestone.reload.name).to eq("Updated Milestone")
      expect(response).to have_http_status(:ok)
    end

    context "with invalid params" do
      it "returns 422" do
        patch admin_work_order_work_order_milestone_path(work_order, milestone),
          params: { work_order_milestone: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_work_order_work_order_milestone_path(work_order, milestone),
          params: { work_order_milestone: { name: "X" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "create_only", description: "Create only").tap do |r|
          r.permissions.create!(resource: "WorkOrderMilestone", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_work_order_work_order_milestone_path(work_order, milestone),
            params: { work_order_milestone: { name: "X" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/work_orders/:work_order_number/work_order_milestones/:id" do
    it "destroys the milestone and returns 200" do
      expect { delete admin_work_order_work_order_milestone_path(work_order, milestone) }
        .to change { work_order.work_order_milestones.count }.by(-1)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_work_order_work_order_milestone_path(work_order, milestone)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "no_destroy", description: "No destroy").tap do |r|
          r.permissions.create!(resource: "WorkOrderMilestone", action: "create")
          r.permissions.create!(resource: "WorkOrderMilestone", action: "update")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { delete admin_work_order_work_order_milestone_path(work_order, milestone) }
          .to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
