require "rails_helper"

RSpec.describe "Admin::Listings::Sales", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "listing_updater", description: "Update listings").tap do |r|
      r.permissions.create!(resource: "Listing", action: "update")
    end
  end

  let(:user)    { create(:user, role: role) }
  let!(:listing) { create(:listing, quantity: 10) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  let(:sale_params) do
    {
      manual_sale: {
        quantity:   1,
        unit_price: listing.price.to_f,
        sold_on:    Date.today.to_s
      }
    }
  end

  describe "POST /admin/listings/:listing_hashid/sales" do
    it "records a sale and redirects to the resulting order" do
      post admin_listing_sales_path(listing), params: sale_params

      expect(response).to redirect_to(admin_order_path(Order.last))
    end

    it "creates an order" do
      expect {
        post admin_listing_sales_path(listing), params: sale_params
      }.to change(Order, :count).by(1)
    end

    it "redirects with alert on failure" do
      post admin_listing_sales_path(listing),
        params: { manual_sale: { quantity: 0, unit_price: "0", sold_on: Date.today.to_s } }

      expect(response).to redirect_to(admin_listing_path(listing, anchor: "inventory-pane"))
      expect(flash[:alert]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_listing_sales_path(listing), params: sale_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks update permission" do
      let(:role) { Role.create!(name: "read_only", description: "Read only") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_listing_sales_path(listing), params: sale_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
