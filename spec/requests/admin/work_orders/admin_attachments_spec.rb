require "rails_helper"

RSpec.describe "Admin::WorkOrders::AdminAttachments", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "wo_manager", description: "Work order manager").tap do |r|
      r.permissions.create!(resource: "WorkOrder", action: "show")
      r.permissions.create!(resource: "WorkOrder", action: "update")
    end
  end

  let(:user)        { create(:user, role: role) }
  let!(:work_order) { create(:work_order) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /admin/work_orders/:work_order_number/admin_attachments" do
    let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/receipt.pdf"), "application/pdf") }

    it "attaches the file to the work order" do
      expect {
        post admin_work_order_admin_attachments_path(work_order),
          params: { files: [ file ] }
      }.to change { work_order.admin_attachments.count }.by(1)
    end

    it "redirects to the work order show page" do
      post admin_work_order_admin_attachments_path(work_order),
        params: { files: [ file ] }

      expect(response).to redirect_to(admin_work_order_path(work_order))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        post admin_work_order_admin_attachments_path(work_order), params: { files: [ file ] }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "WorkOrder", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_work_order_admin_attachments_path(work_order), params: { files: [ file ] }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/work_orders/:work_order_number/admin_attachments/:id" do
    let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/receipt.pdf"), "application/pdf") }

    before { work_order.admin_attachments.attach(io: file, filename: "sample.pdf", content_type: "application/pdf") }

    let(:attachment) do
      ActiveStorage::Attachment.find_by!(record: work_order, name: "admin_attachments")
    end

    it "removes the attachment" do
      expect {
        delete admin_work_order_admin_attachment_path(work_order, attachment)
      }.to change { work_order.admin_attachments.count }.by(-1)
    end

    it "redirects to the work order show page" do
      delete admin_work_order_admin_attachment_path(work_order, attachment)

      expect(response).to redirect_to(admin_work_order_path(work_order))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign-in" do
        delete admin_work_order_admin_attachment_path(work_order, attachment)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
