require "rails_helper"

RSpec.describe "Admin::Invoices", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "invoice_manager", description: "Manage invoices").tap do |r|
      r.permissions.create!(resource: "Invoice", action: "index")
      r.permissions.create!(resource: "Invoice", action: "show")
    end
  end

  let(:user)    { create(:user, role: role) }
  let(:buyer)   { create(:user) }
  let(:auction) { create(:auction) }
  let!(:invoice) { create(:invoice, user: buyer, auction: auction, total_cents: 15_050) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/invoices" do
    it "returns 200" do
      get admin_invoices_path

      expect(response).to have_http_status(:ok)
    end

    it "displays the invoice number" do
      get admin_invoices_path

      expect(response.body).to include(invoice.number)
    end

    it "displays the buyer email" do
      get admin_invoices_path

      expect(response.body).to include(buyer.email_address)
    end

    it "displays the auction name" do
      get admin_invoices_path

      expect(response.body).to include(auction.name)
    end

    it "displays the invoice total" do
      get admin_invoices_path

      expect(response.body).to include("150.50")
    end

    it "displays the invoice status badge" do
      get admin_invoices_path

      expect(response.body).to include("Unpaid")
    end

    context "with a paid invoice" do
      let!(:invoice) { create(:invoice, :paid, user: buyer, auction: auction) }

      it "displays the paid status badge" do
        get admin_invoices_path

        expect(response.body).to include("Paid")
      end
    end

    context "when there are multiple invoices" do
      let!(:older_invoice) { create(:invoice, user: buyer, auction: auction, created_at: 2.days.ago) }
      let!(:newer_invoice) { create(:invoice, user: buyer, auction: auction, created_at: 1.day.ago) }

      it "shows newer invoices before older ones" do
        get admin_invoices_path

        expect(response.body.index(newer_invoice.number)).to be < response.body.index(older_invoice.number)
      end
    end

    context "when there are invoices for multiple users" do
      let(:other_buyer)   { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_buyer, auction: auction) }

      it "displays all invoices regardless of user" do
        get admin_invoices_path

        expect(response.body).to include(invoice.number)
        expect(response.body).to include(other_invoice.number)
      end
    end

    context "infinite scroll — turbo stream page request" do
      before { create_list(:invoice, 25, user: buyer, auction: auction) }

      it "appends rows and replaces the sentinel" do
        get admin_invoices_path

        next_url  = response.body[/data-url="([^"]+)"/, 1]
        next_page = URI.decode_www_form(URI.parse(next_url).query).to_h["page"]

        get admin_invoices_path(page: next_page),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to start_with("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="append" target="admin-invoices-tbody"')
        expect(response.body).to include('action="replace" target="sentinel"')
      end
    end

    context "filtering by user email" do
      let(:other_buyer)    { create(:user) }
      let!(:other_invoice) { create(:invoice, user: other_buyer, auction: auction) }

      it "returns only invoices matching the email" do
        get admin_invoices_path, params: { q: { user_email_address_cont: buyer.email_address } }

        expect(response.body).to include(invoice.number)
        expect(response.body).not_to include(other_invoice.number)
      end

      it "returns no invoices when no email matches" do
        get admin_invoices_path, params: { q: { user_email_address_cont: "nobody@example.com" } }

        expect(response.body).not_to include(invoice.number)
        expect(response.body).not_to include(other_invoice.number)
      end
    end

    context "filtering by auction name" do
      let(:other_auction)  { create(:auction, name: "Other Auction") }
      let!(:other_invoice) { create(:invoice, user: buyer, auction: other_auction) }

      it "returns only invoices matching the auction name" do
        get admin_invoices_path, params: { q: { auction_name_cont: auction.name } }

        expect(response.body).to include(invoice.number)
        expect(response.body).not_to include(other_invoice.number)
      end

      it "returns no invoices when no auction matches" do
        get admin_invoices_path, params: { q: { auction_name_cont: "Nonexistent Auction" } }

        expect(response.body).not_to include(invoice.number)
        expect(response.body).not_to include(other_invoice.number)
      end
    end

    context "filtering by status" do
      let!(:paid_invoice) { create(:invoice, :paid, user: buyer, auction: auction) }

      it "returns only unpaid invoices when filtering by unpaid" do
        get admin_invoices_path, params: { q: { status_eq: "unpaid" } }

        expect(response.body).to include(invoice.number)
        expect(response.body).not_to include(paid_invoice.number)
      end

      it "returns only paid invoices when filtering by paid" do
        get admin_invoices_path, params: { q: { status_eq: "paid" } }

        expect(response.body).to include(paid_invoice.number)
        expect(response.body).not_to include(invoice.number)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_invoices_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_invoices", description: "No invoice access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_invoices_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/invoices/:number" do
    it "returns 200" do
      get admin_invoice_path(invoice)

      expect(response).to have_http_status(:ok)
    end

    it "displays the invoice number" do
      get admin_invoice_path(invoice)

      expect(response.body).to include(invoice.number)
    end

    it "displays the buyer email" do
      get admin_invoice_path(invoice)

      expect(response.body).to include(buyer.email_address)
    end

    it "displays the unpaid status badge" do
      get admin_invoice_path(invoice)

      expect(response.body).to include("Unpaid")
    end

    context "with a paid invoice" do
      let!(:invoice) { create(:invoice, :paid, user: buyer, auction: auction) }

      it "displays the paid status badge" do
        get admin_invoice_path(invoice)

        expect(response.body).to include("Paid")
      end
    end

    context "with invoice items" do
      let!(:invoice) { create(:invoice, :with_items, user: buyer, auction: auction) }

      it "displays the item names" do
        get admin_invoice_path(invoice)

        expect(response.body).to include("Second Item")
      end
    end

    context "when the invoice has an auction source" do
      it "displays the auction name" do
        get admin_invoice_path(invoice)

        expect(response.body).to include(auction.name)
      end
    end

    context "when the invoice has an offer source" do
      let(:listing) { create(:listing) }
      let(:offer)   { create(:offer, listing: listing, user: buyer) }
      let!(:invoice) { create(:invoice, user: buyer, auction: nil, offer: offer, total_cents: offer.amount_cents) }

      it "displays the listing name" do
        get admin_invoice_path(invoice)

        expect(response.body).to include(listing.name)
      end
    end

    context "with an unknown invoice number" do
      it "returns 404" do
        get "/admin/invoices/INV-DOESNOTEXIST"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_invoice_path(invoice)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) do
        Role.create!(name: "index_only", description: "Index only").tap do |r|
          r.permissions.create!(resource: "Invoice", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_invoice_path(invoice) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
