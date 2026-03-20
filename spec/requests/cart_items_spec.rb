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

      it "adds the listing to a guest cart" do
        expect {
          post cart_items_path, params: { listing_id: listing.id }
        }.to change { CartItem.count }.by(1)
      end

      it "redirects back" do
        post cart_items_path, params: { listing_id: listing.id }

        expect(response).to have_http_status(:redirect)
      end
    end

    context "when the listing is a rental" do
      let!(:listing)   { create(:listing, listing_type: :rental) }
      let!(:rate_plan) { create(:listings_rental_rate_plan, listing: listing) }
      let(:start_at)   { 1.day.from_now.beginning_of_hour }
      let(:end_at)     { 2.days.from_now.beginning_of_hour }

      it "adds the rental to the user's cart" do
        expect {
          post cart_items_path, params: {
            listing_id: listing.id,
            rental_start_at: start_at.to_s, rental_end_at: end_at.to_s
          }
        }.to change { user.cart_items.count }.by(1)
      end

      it "creates an associated rental booking" do
        post cart_items_path, params: {
          listing_id: listing.id,
          rental_start_at: start_at.to_s, rental_end_at: end_at.to_s
        }
        expect(user.cart_items.last.rental_booking).to be_present
      end

      it "sets a notice flash" do
        post cart_items_path, params: {
          listing_id: listing.id,
          rental_start_at: start_at.to_s, rental_end_at: end_at.to_s
        }
        expect(flash[:notice]).to match("Rental added to cart.")
      end

      context "when end_at is before start_at" do
        it "does not create a cart item" do
          expect {
            post cart_items_path, params: {
              listing_id: listing.id,
              rental_start_at: end_at.to_s, rental_end_at: start_at.to_s
            }
          }.not_to change { user.cart_items.count }
        end

        it "sets an alert flash" do
          post cart_items_path, params: {
            listing_id: listing.id,
            rental_start_at: end_at.to_s, rental_end_at: start_at.to_s
          }
          expect(flash[:alert]).to eq("Please select a valid date and time range.")
        end
      end

      context "when dates are missing" do
        it "does not create a cart item" do
          expect {
            post cart_items_path, params: { listing_id: listing.id }
          }.not_to change { user.cart_items.count }
        end

        it "sets an alert flash" do
          post cart_items_path, params: { listing_id: listing.id }
          expect(flash[:alert]).to eq("Please select a valid date and time range.")
        end
      end
    end
  end

  describe "PATCH /cart_items/:id" do
    let!(:listing)   { create(:listing, quantity: 10) }
    let!(:cart_item) { user.cart_items.create!(listing: listing, quantity: 1) }

    it "updates the quantity" do
      patch cart_item_path(cart_item), params: { quantity: 3 }

      expect(cart_item.reload.quantity).to eq(3)
    end

    it "sets a notice flash" do
      patch cart_item_path(cart_item), params: { quantity: 2 }

      expect(flash[:notice]).to eq("Quantity updated.")
    end

    it "redirects back" do
      patch cart_item_path(cart_item), params: { quantity: 2 }

      expect(response).to have_http_status(:redirect)
    end

    context "when quantity exceeds the listing's stock" do
      it "clamps to the listing quantity" do
        patch cart_item_path(cart_item), params: { quantity: 999 }

        expect(cart_item.reload.quantity).to eq(listing.quantity)
      end
    end

    context "when quantity is less than 1" do
      it "clamps to 1" do
        patch cart_item_path(cart_item), params: { quantity: 0 }

        expect(cart_item.reload.quantity).to eq(1)
      end
    end

    context "when the cart item belongs to another user" do
      let(:other_user) { create(:user) }
      let!(:other_item) { other_user.cart_items.create!(listing: listing) }

      it "returns 404" do
        patch cart_item_path(other_item), params: { quantity: 2 }

        expect(response).to have_http_status(:not_found)
      end

      it "does not update the other user's cart item" do
        patch cart_item_path(other_item), params: { quantity: 5 }

        expect(other_item.reload.quantity).to eq(1)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "returns 404" do
        patch cart_item_path(cart_item), params: { quantity: 2 }

        expect(response).to have_http_status(:not_found)
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

      it "returns 404" do
        delete cart_item_path(cart_item)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
