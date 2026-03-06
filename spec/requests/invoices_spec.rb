require "rails_helper"

RSpec.describe "Invoices", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(name: "Test", key: "test", default: true)
  end

  let(:user)    { create(:user) }
  let(:auction) { create(:auction) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /profile/edit — invoices tab" do
    context "when the user has no invoices" do
      it "returns 200" do
        get edit_profile_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the empty state message" do
        get edit_profile_path

        expect(response.body).to include("You have no invoices yet.")
      end
    end

    context "when the user has invoices" do
      let!(:invoice) { create(:invoice, user: user, auction: auction, total_cents: 20_050) }

      it "displays the invoice number" do
        get edit_profile_path

        expect(response.body).to include(invoice.number)
      end

      it "displays the auction name" do
        get edit_profile_path

        expect(response.body).to include(auction.name)
      end

      it "displays the invoice total" do
        get edit_profile_path

        expect(response.body).to include("200.50")
      end

      it "displays the unpaid status badge" do
        get edit_profile_path

        expect(response.body).to include("Unpaid")
      end

      it "shows a Pay button for unpaid invoices" do
        get edit_profile_path

        expect(response.body).to include(pay_invoice_path(invoice))
      end
    end

    context "when the user has a paid invoice" do
      let!(:invoice) { create(:invoice, :paid, user: user, auction: auction) }

      it "displays the paid status badge" do
        get edit_profile_path

        expect(response.body).to include("Paid")
      end

      it "does not show a Pay button" do
        get edit_profile_path

        expect(response.body).not_to include(pay_invoice_path(invoice))
      end
    end

    context "when the user has multiple invoices" do
      let!(:older_invoice) { create(:invoice, user: user, auction: auction, created_at: 2.days.ago) }
      let!(:newer_invoice) { create(:invoice, user: user, auction: auction, created_at: 1.day.ago) }

      it "shows newer invoices before older ones" do
        get edit_profile_path

        expect(response.body.index(newer_invoice.number)).to be < response.body.index(older_invoice.number)
      end
    end

    context "when another user has invoices" do
      let(:other_user)    { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_user, auction: auction) }

      it "does not display the other user's invoice" do
        get edit_profile_path

        expect(response.body).not_to include(other_invoice.number)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get edit_profile_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /invoices/:number" do
    let!(:invoice) { create(:invoice, :with_items, user: user, auction: auction, total_cents: 10_000) }

    it "returns 200" do
      get invoice_path(invoice)

      expect(response).to have_http_status(:ok)
    end

    it "displays the invoice number" do
      get invoice_path(invoice)

      expect(response.body).to include(invoice.number)
    end

    it "displays the auction name" do
      get invoice_path(invoice)

      expect(response.body).to include(auction.name)
    end

    it "displays each line item" do
      get invoice_path(invoice)

      invoice.invoice_items.each do |item|
        expect(response.body).to include(item.name)
      end
    end

    it "displays the invoice total" do
      get invoice_path(invoice)

      expect(response.body).to include("100.50")
    end

    it "shows the Pay Invoice button for an unpaid invoice" do
      get invoice_path(invoice)

      expect(response.body).to include(pay_invoice_path(invoice))
    end

    context "when the invoice is paid" do
      let!(:invoice) { create(:invoice, :paid, :with_items, user: user, auction: auction) }

      it "does not show the Pay Invoice button" do
        get invoice_path(invoice)

        expect(response.body).not_to include(pay_invoice_path(invoice))
      end

      it "shows the paid badge" do
        get invoice_path(invoice)

        expect(response.body).to include("Paid")
      end
    end

    context "when the invoice belongs to another user" do
      let(:other_user)    { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_user, auction: auction) }

      it "returns 404" do
        get invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get invoice_path(invoice)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /invoices/:number/pay" do
    let!(:invoice) { create(:invoice, :with_items, user: user, auction: auction) }

    it "clears the user's existing cart items" do
      listing = create(:listing)
      user.cart_items.create!(listing: listing)

      post pay_invoice_path(invoice)

      expect(user.cart_items.where(invoice_item_id: nil)).to be_empty
    end

    it "adds invoice items to the cart" do
      post pay_invoice_path(invoice)

      expect(user.cart_items.count).to eq(invoice.invoice_items.count)
    end

    it "sets invoice_item on each cart item" do
      post pay_invoice_path(invoice)

      expect(user.cart_items.pluck(:invoice_item_id)).to all(be_present)
    end

    it "redirects to the cart with a notice" do
      post pay_invoice_path(invoice)

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to be_present
    end

    context "when the invoice is already paid" do
      let!(:invoice) { create(:invoice, :paid, user: user, auction: auction) }

      it "redirects to the profile with an alert" do
        post pay_invoice_path(invoice)

        expect(response).to redirect_to(edit_profile_path)
        expect(flash[:alert]).to be_present
      end

      it "does not modify the cart" do
        expect { post pay_invoice_path(invoice) }.not_to change { user.cart_items.count }
      end
    end

    context "when the invoice belongs to another user" do
      let(:other_user)    { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_user, auction: auction) }

      it "returns 404" do
        post pay_invoice_path(other_invoice)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post pay_invoice_path(invoice)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
