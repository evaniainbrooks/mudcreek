require "rails_helper"

RSpec.describe "CartItems", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user) { create(:user) }
  let!(:listing) { create(:listing) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "POST /cart_items" do
    it "adds the listing to the user's cart" do
      expect {
        post cart_items_path, params: { listing_id: listing.id }
      }.to change { user.cart_items.count }.by(1)
    end

    it "sets a notice flash" do
      post cart_items_path, params: { listing_id: listing.id }

      expect(flash[:notice]).to match("Added to cart.")
    end

    it "redirects back" do
      post cart_items_path, params: { listing_id: listing.id }

      expect(response).to have_http_status(:redirect)
    end

    context "when the listing is already in the cart" do
      before { user.cart_items.create!(listing: listing) }

      it "does not add a duplicate cart item" do
        expect {
          post cart_items_path, params: { listing_id: listing.id }
        }.not_to change { user.cart_items.count }
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post cart_items_path, params: { listing_id: listing.id }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /cart_items/:id" do
    let!(:cart_item) { user.cart_items.create!(listing: listing) }

    it "removes the cart item" do
      expect {
        delete cart_item_path(cart_item)
      }.to change { user.cart_items.count }.by(-1)
    end

    it "sets a notice flash" do
      delete cart_item_path(cart_item)

      expect(flash[:notice]).to eq("Removed from cart.")
    end

    it "redirects back" do
      delete cart_item_path(cart_item)

      expect(response).to have_http_status(:redirect)
    end

    context "when the cart item belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_listing) { create(:listing) }
      let!(:other_item) { other_user.cart_items.create!(listing: other_listing) }

      it "returns 404" do
        delete cart_item_path(other_item)

        expect(response).to have_http_status(:not_found)
      end

      it "does not destroy the other user's cart item" do
        delete cart_item_path(other_item)

        expect(CartItem.unscoped.find_by(id: other_item.id)).to be_present
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete cart_item_path(cart_item)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
