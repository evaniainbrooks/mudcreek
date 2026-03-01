require "rails_helper"

RSpec.describe "CartDeliveryMethods", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }
  let!(:delivery_method) { create(:delivery_method) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /cart_delivery_method" do
    context "with a valid, active delivery method" do
      it "stores the delivery method id in the session" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(session[:delivery_method_id]).to eq(delivery_method.id)
      end

      it "redirects to the cart" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(response).to redirect_to(cart_path)
      end

      it "sets a notice flash including the method name" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(flash[:notice]).to include(delivery_method.name)
      end
    end

    context "with an inactive delivery method" do
      let!(:delivery_method) { create(:delivery_method, :inactive) }

      it "does not store the delivery method in the session" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(session[:delivery_method_id]).to be_nil
      end

      it "redirects to the cart with an alert" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to eq("Delivery method not found.")
      end
    end

    context "with a non-existent delivery method id" do
      it "redirects to the cart with an alert" do
        post cart_delivery_method_path, params: { delivery_method_id: 0 }

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to eq("Delivery method not found.")
      end

      it "does not store anything in the session" do
        post cart_delivery_method_path, params: { delivery_method_id: 0 }

        expect(session[:delivery_method_id]).to be_nil
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post cart_delivery_method_path, params: { delivery_method_id: delivery_method.id }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /cart_delivery_method" do
    before { session[:delivery_method_id] = delivery_method.id }

    it "removes the delivery method from the session" do
      delete cart_delivery_method_path

      expect(session[:delivery_method_id]).to be_nil
    end

    it "redirects to the cart" do
      delete cart_delivery_method_path

      expect(response).to redirect_to(cart_path)
    end

    it "sets a notice flash" do
      delete cart_delivery_method_path

      expect(flash[:notice]).to eq("Delivery method removed.")
    end

    context "when no delivery method is in the session" do
      before { session.delete(:delivery_method_id) }

      it "still redirects to the cart" do
        delete cart_delivery_method_path

        expect(response).to redirect_to(cart_path)
      end

      it "sets the notice flash" do
        delete cart_delivery_method_path

        expect(flash[:notice]).to eq("Delivery method removed.")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete cart_delivery_method_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
