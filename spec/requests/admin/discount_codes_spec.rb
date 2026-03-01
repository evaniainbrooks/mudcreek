require "rails_helper"

RSpec.describe "Admin::DiscountCodes", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "discount_manager", description: "Manage discount codes").tap do |r|
      r.permissions.create!(resource: "DiscountCode", action: "index")
      r.permissions.create!(resource: "DiscountCode", action: "create")
      r.permissions.create!(resource: "DiscountCode", action: "destroy")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:discount_code) { create(:discount_code) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/discount_codes" do
    it "returns 200" do
      get admin_discount_codes_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the discount code key in the response" do
      get admin_discount_codes_path

      expect(response.body).to include(discount_code.key)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_discount_codes_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_discounts", description: "No discount access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_discount_codes_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/discount_codes" do
    context "with valid fixed params" do
      let(:valid_params) { { discount_code: { key: "SAVE10", discount_type: "fixed", amount: "10.00" } } }

      it "creates a new discount code" do
        expect {
          post admin_discount_codes_path, params: valid_params
        }.to change(DiscountCode, :count).by(1)
      end

      it "stores the amount in cents" do
        post admin_discount_codes_path, params: valid_params

        expect(DiscountCode.find_by(key: "SAVE10").amount_cents).to eq(1000)
      end

      it "redirects to the index with a notice including the key" do
        post admin_discount_codes_path, params: valid_params

        expect(response).to redirect_to(admin_discount_codes_path)
        expect(flash[:notice]).to include("SAVE10")
      end
    end

    context "with valid percentage params" do
      let(:valid_params) { { discount_code: { key: "HALF15", discount_type: "percentage", amount: "15.00" } } }

      it "creates a percentage discount code" do
        post admin_discount_codes_path, params: valid_params

        expect(DiscountCode.find_by(key: "HALF15").discount_type).to eq("percentage")
      end
    end

    context "with start and end dates" do
      let(:start_at) { 1.day.from_now.beginning_of_hour }
      let(:end_at)   { 1.month.from_now.beginning_of_hour }
      let(:valid_params) do
        { discount_code: { key: "TIMED", discount_type: "fixed", amount: "5.00",
                           start_at: start_at, end_at: end_at } }
      end

      it "persists the start and end dates" do
        post admin_discount_codes_path, params: valid_params

        code = DiscountCode.find_by(key: "TIMED")
        expect(code.start_at).to be_within(1.second).of(start_at)
        expect(code.end_at).to be_within(1.second).of(end_at)
      end
    end

    context "with a missing key" do
      it "does not create a discount code" do
        expect {
          post admin_discount_codes_path, params: { discount_code: { key: "", discount_type: "fixed", amount: "10.00" } }
        }.not_to change(DiscountCode, :count)
      end

      it "re-renders the index with unprocessable entity status" do
        post admin_discount_codes_path, params: { discount_code: { key: "", discount_type: "fixed", amount: "10.00" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a duplicate key" do
      it "does not create a discount code" do
        expect {
          post admin_discount_codes_path, params: { discount_code: { key: discount_code.key, discount_type: "fixed", amount: "10.00" } }
        }.not_to change(DiscountCode, :count)
      end

      it "re-renders the index with unprocessable entity status" do
        post admin_discount_codes_path, params: { discount_code: { key: discount_code.key, discount_type: "fixed", amount: "10.00" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_discount_codes_path, params: { discount_code: { key: "SAVE10", discount_type: "fixed", amount: "10.00" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_discounts", description: "Read-only discount access").tap do |r|
          r.permissions.create!(resource: "DiscountCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_discount_codes_path, params: { discount_code: { key: "SAVE10", discount_type: "fixed", amount: "10.00" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/discount_codes/:id" do
    it "destroys the discount code" do
      expect {
        delete admin_discount_code_path(discount_code)
      }.to change(DiscountCode, :count).by(-1)
    end

    it "redirects to the index with a notice including the key" do
      delete admin_discount_code_path(discount_code)

      expect(response).to redirect_to(admin_discount_codes_path)
      expect(flash[:notice]).to include(discount_code.key)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_discount_code_path(discount_code)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_discounts", description: "Read-only discount access").tap do |r|
          r.permissions.create!(resource: "DiscountCode", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_discount_code_path(discount_code)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
