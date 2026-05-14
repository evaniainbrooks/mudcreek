require "rails_helper"

RSpec.describe "Admin::Inquiries", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, email_address: "info@test.example.com")
  end

  let(:role) do
    Role.create!(name: "inquiry_manager", description: "Manage inquiries").tap do |r|
      r.permissions.create!(resource: "Inquiry", action: "index")
      r.permissions.create!(resource: "Inquiry", action: "show")
      r.permissions.create!(resource: "Inquiry", action: "update")
    end
  end

  let(:viewer)       { create(:user, role: role) }
  let(:inquiry_form) { create(:inquiry_form) }
  let!(:inquiry)     { create(:inquiry, inquiry_form: inquiry_form) }

  before { post session_path, params: { email_address: viewer.email_address, password: "password" } }

  describe "GET /admin/inquiries" do
    it "returns 200" do
      get admin_inquiries_path

      expect(response).to have_http_status(:ok)
    end

    it "lists inquiries" do
      get admin_inquiries_path

      expect(response.body).to include(inquiry.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_inquiries_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_inquiries_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/inquiries/:id" do
    it "returns 200" do
      get admin_inquiry_path(inquiry)

      expect(response).to have_http_status(:ok)
    end

    it "displays the inquiry name" do
      get admin_inquiry_path(inquiry)

      expect(response.body).to include(inquiry.name)
    end

    it "displays the inquiry email" do
      get admin_inquiry_path(inquiry)

      expect(response.body).to include(inquiry.email)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_inquiry_path(inquiry)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_inquiry_path(inquiry) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/inquiries/:id" do
    it "updates the status and redirects" do
      patch admin_inquiry_path(inquiry), params: { inquiry: { status: "resolved" } }

      expect(inquiry.reload.status).to eq("resolved")
      expect(response).to redirect_to(admin_inquiry_path(inquiry))
    end

    it "updates admin_notes" do
      patch admin_inquiry_path(inquiry), params: { inquiry: { admin_notes: "Followed up." } }

      expect(inquiry.reload.admin_notes).to eq("Followed up.")
    end

    it "sets a flash notice" do
      patch admin_inquiry_path(inquiry), params: { inquiry: { status: "in_progress" } }

      expect(flash[:notice]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_inquiry_path(inquiry), params: { inquiry: { status: "resolved" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "show_only", description: "Show only").tap do |r|
          r.permissions.create!(resource: "Inquiry", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_inquiry_path(inquiry), params: { inquiry: { status: "resolved" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
