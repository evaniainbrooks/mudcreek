require "rails_helper"

RSpec.describe "CartDiscounts", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /cart_discount" do
    context "with a valid, active discount code" do
      let!(:discount_code) { create(:discount_code, :active) }

      it "stores the discount code id in the session" do
        post cart_discount_path, params: { discount_code: discount_code.key }

        expect(session[:discount_code_id]).to eq(discount_code.id)
      end

      it "redirects to the cart" do
        post cart_discount_path, params: { discount_code: discount_code.key }

        expect(response).to redirect_to(cart_path)
      end

      it "sets a notice flash including the code key" do
        post cart_discount_path, params: { discount_code: discount_code.key }

        expect(flash[:notice]).to include(discount_code.key)
      end

      it "upcases and strips the submitted code" do
        post cart_discount_path, params: { discount_code: " #{discount_code.key.downcase} " }

        expect(session[:discount_code_id]).to eq(discount_code.id)
      end
    end

    context "with an inactive discount code" do
      let!(:discount_code) { create(:discount_code, :expired) }

      it "does not store the discount code in the session" do
        post cart_discount_path, params: { discount_code: discount_code.key }

        expect(session[:discount_code_id]).to be_nil
      end

      it "redirects to the cart with an alert" do
        post cart_discount_path, params: { discount_code: discount_code.key }

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to eq("This discount code is not currently active.")
      end
    end

    context "with a non-existent discount code" do
      it "redirects to the cart with an alert" do
        post cart_discount_path, params: { discount_code: "INVALID" }

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to eq("Discount code not found.")
      end

      it "does not store anything in the session" do
        post cart_discount_path, params: { discount_code: "INVALID" }

        expect(session[:discount_code_id]).to be_nil
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post cart_discount_path, params: { discount_code: "ANYCODE" }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /cart_discount" do
    let!(:discount_code) { create(:discount_code, :active) }

    before { session[:discount_code_id] = discount_code.id }

    it "removes the discount code from the session" do
      delete cart_discount_path

      expect(session[:discount_code_id]).to be_nil
    end

    it "redirects to the cart" do
      delete cart_discount_path

      expect(response).to redirect_to(cart_path)
    end

    it "sets a notice flash" do
      delete cart_discount_path

      expect(flash[:notice]).to eq("Discount code removed.")
    end

    context "when no discount code is in the session" do
      before { session.delete(:discount_code_id) }

      it "still redirects to the cart" do
        delete cart_discount_path

        expect(response).to redirect_to(cart_path)
      end

      it "sets the notice flash" do
        delete cart_discount_path

        expect(flash[:notice]).to eq("Discount code removed.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete cart_discount_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
