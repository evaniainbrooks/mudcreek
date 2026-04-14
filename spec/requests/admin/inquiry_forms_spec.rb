require "rails_helper"

RSpec.describe "Admin::InquiryForms", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, email_address: "info@test.example.com")
  end

  let(:role) do
    Role.create!(name: "form_manager", description: "Manage inquiry forms").tap do |r|
      r.permissions.create!(resource: "InquiryForm", action: "index")
      r.permissions.create!(resource: "InquiryForm", action: "show")
      r.permissions.create!(resource: "InquiryForm", action: "create")
      r.permissions.create!(resource: "InquiryForm", action: "update")
      r.permissions.create!(resource: "InquiryForm", action: "destroy")
    end
  end

  let(:viewer)       { create(:user, role: role) }
  let(:recipient)    { create(:user) }
  let!(:form)        { create(:inquiry_form, notification_recipient: recipient) }

  before { post session_path, params: { email_address: viewer.email_address, password: "password" } }

  describe "GET /admin/inquiry_forms" do
    it "returns 200" do
      get admin_inquiry_forms_path

      expect(response).to have_http_status(:ok)
    end

    it "lists inquiry forms" do
      get admin_inquiry_forms_path

      expect(response.body).to include(form.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_inquiry_forms_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_inquiry_forms_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/inquiry_forms/:id" do
    it "returns 200" do
      get admin_inquiry_form_path(form)

      expect(response).to have_http_status(:ok)
    end

    it "displays the form name" do
      get admin_inquiry_form_path(form)

      expect(response.body).to include(form.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_inquiry_form_path(form)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_access", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_inquiry_form_path(form) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/inquiry_forms/new" do
    it "returns 200" do
      get new_admin_inquiry_form_path

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get new_admin_inquiry_form_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /admin/inquiry_forms" do
    let(:valid_params) do
      {
        inquiry_form: {
          name: "Contact Us",
          notification_recipient_id: recipient.id,
          published: true
        }
      }
    end

    it "creates a new inquiry form" do
      expect {
        post admin_inquiry_forms_path, params: valid_params
      }.to change(InquiryForm, :count).by(1)
    end

    it "derives the slug from the name" do
      post admin_inquiry_forms_path, params: valid_params

      expect(InquiryForm.find_by!(name: "Contact Us").slug).to eq("contact-us")
    end

    it "redirects to the index with a notice" do
      post admin_inquiry_forms_path, params: valid_params

      expect(response).to redirect_to(admin_inquiry_forms_path)
      expect(flash[:notice]).to eq("Inquiry form was successfully created.")
    end

    context "with invalid params" do
      it "returns 422" do
        post admin_inquiry_forms_path, params: { inquiry_form: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a form" do
        expect {
          post admin_inquiry_forms_path, params: { inquiry_form: { name: "" } }
        }.not_to change(InquiryForm, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_inquiry_forms_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "InquiryForm", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { post admin_inquiry_forms_path, params: valid_params }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/inquiry_forms/:id/edit" do
    it "returns 200" do
      get edit_admin_inquiry_form_path(form)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/inquiry_forms/:id" do
    it "updates the form" do
      patch admin_inquiry_form_path(form), params: { inquiry_form: { name: "Updated Name" } }

      expect(form.reload.name).to eq("Updated Name")
    end

    it "redirects to the index with a notice" do
      patch admin_inquiry_form_path(form), params: { inquiry_form: { name: "Updated Name" } }

      expect(response).to redirect_to(admin_inquiry_forms_path)
      expect(flash[:notice]).to eq("Inquiry form was successfully updated.")
    end

    it "persists the cta_label" do
      patch admin_inquiry_form_path(form), params: { inquiry_form: { cta_label: "Submit Request" } }

      expect(form.reload.cta_label).to eq("Submit Request")
    end

    it "persists the redirect_path" do
      patch admin_inquiry_form_path(form), params: { inquiry_form: { redirect_path: "/thank-you" } }

      expect(form.reload.redirect_path).to eq("/thank-you")
    end

    context "with invalid params" do
      it "returns 422" do
        patch admin_inquiry_form_path(form), params: { inquiry_form: { name: "" } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_inquiry_form_path(form), params: { inquiry_form: { name: "Updated" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "InquiryForm", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_inquiry_form_path(form), params: { inquiry_form: { name: "Updated" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/inquiry_forms/:id" do
    it "destroys the form" do
      expect {
        delete admin_inquiry_form_path(form)
      }.to change(InquiryForm, :count).by(-1)
    end

    it "redirects to the index with a notice" do
      delete admin_inquiry_form_path(form)

      expect(response).to redirect_to(admin_inquiry_forms_path)
      expect(flash[:notice]).to eq("Inquiry form was successfully deleted.")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_inquiry_form_path(form)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "InquiryForm", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { delete admin_inquiry_form_path(form) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
