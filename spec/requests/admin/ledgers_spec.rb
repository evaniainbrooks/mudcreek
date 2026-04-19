require "rails_helper"

RSpec.describe "Admin::Ledgers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "ledger_manager", description: "Manage ledgers").tap do |r|
      r.permissions.create!(resource: "Ledger",       action: "index")
      r.permissions.create!(resource: "Ledger",       action: "show")
      r.permissions.create!(resource: "Ledger",       action: "create")
      r.permissions.create!(resource: "Ledger",       action: "update")
      r.permissions.create!(resource: "Ledger",       action: "destroy")
      r.permissions.create!(resource: "Ledger::Entry", action: "create")
      r.permissions.create!(resource: "Ledger::Entry", action: "destroy")
    end
  end

  let(:user)    { create(:user, role: role) }
  let!(:ledger) { create(:ledger, name: "Canteen") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/ledgers" do
    it "returns 200 and lists the ledger" do
      get admin_ledgers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Canteen")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_ledgers_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_ledgers", description: "No ledger access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_ledgers_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/ledgers/:id" do
    it "returns 200 and shows the ledger name" do
      get admin_ledger_path(ledger)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Canteen")
    end

    it "shows credit and debit summary cards" do
      create(:ledger_entry, ledger: ledger, entry_type: "credit", amount: 50.00)
      create(:ledger_entry, :debit, ledger: ledger, amount: 20.00)

      get admin_ledger_path(ledger)

      expect(response.body).to include("$50.00")
      expect(response.body).to include("$20.00")
      expect(response.body).to include("$30.00")
    end

    it "shows entry rows" do
      create(:ledger_entry, ledger: ledger, description: "Coffee sales", amount: 12.50)

      get admin_ledger_path(ledger)

      expect(response.body).to include("Coffee sales")
      expect(response.body).to include("$12.50")
    end

    context "when the tenant has no timezone set" do
      before { Current.tenant.update!(timezone: "") }

      it "returns 200 without raising ArgumentError" do
        get admin_ledger_path(ledger)

        expect(response).to have_http_status(:ok)
      end

      it "renders the entry form with entries present" do
        create(:ledger_entry, ledger: ledger, description: "Supply run")

        get admin_ledger_path(ledger)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Supply run")
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_ledger_path(ledger)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/ledgers/new" do
    it "returns 200" do
      get new_admin_ledger_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/ledgers" do
    it "creates the ledger and redirects to show" do
      expect {
        post admin_ledgers_path, params: { ledger: { name: "Cleaning Supplies" } }
      }.to change(Ledger, :count).by(1)

      expect(response).to redirect_to(admin_ledger_path(Ledger.last))
    end

    it "re-renders new with unprocessable_content on blank name" do
      post admin_ledgers_path, params: { ledger: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_ledgers_path, params: { ledger: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/ledgers/:id" do
    it "updates the ledger name" do
      patch admin_ledger_path(ledger), params: { ledger: { name: "Equipment Maintenance" } }

      expect(ledger.reload.name).to eq("Equipment Maintenance")
      expect(response).to redirect_to(admin_ledger_path(ledger))
    end

    it "re-renders edit with unprocessable_content on blank name" do
      patch admin_ledger_path(ledger), params: { ledger: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/ledgers/:id" do
    it "destroys the ledger and redirects to index" do
      expect {
        delete admin_ledger_path(ledger)
      }.to change(Ledger, :count).by(-1)

      expect(response).to redirect_to(admin_ledgers_path)
    end

    it "destroys associated entries" do
      create(:ledger_entry, ledger: ledger)

      expect {
        delete admin_ledger_path(ledger)
      }.to change(Ledger::Entry, :count).by(-1)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/ledgers/:id/entries" do
    let(:entry_params) do
      { ledger_entry: { description: "Morning sales", entry_type: "credit", amount: "25.00", recorded_at: Time.current.to_s } }
    end

    it "creates an entry" do
      expect {
        post admin_ledger_entries_path(ledger), params: entry_params,
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Ledger::Entry, :count).by(1)
    end

    it "responds with turbo stream on success" do
      post admin_ledger_entries_path(ledger), params: entry_params,
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "turbo stream response includes updated tax credit, debit, and balance cards" do
      create(:ledger_entry, :debit, ledger: ledger, amount: 10.80, taxed: true)

      post admin_ledger_entries_path(ledger),
        params: { ledger_entry: { description: "Coffee sales", entry_type: "credit", amount: "21.60", taxed: "1", recorded_at: Time.current.to_s } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      tax_rate = ledger.tax_rate
      credit_tax = (21.60 - (21.60 / (1 + tax_rate)).round(2)).round(2)
      debit_tax  = (10.80 - (10.80 / (1 + tax_rate)).round(2)).round(2)
      balance    = credit_tax - debit_tax

      expect(response.body).to include("Tax Credits")
      expect(response.body).to include("Tax Debits")
      expect(response.body).to include("Tax Balance")
      expect(response.body).to include(ActionController::Base.helpers.number_to_currency(credit_tax))
      expect(response.body).to include(ActionController::Base.helpers.number_to_currency(debit_tax))
      expect(response.body).to include(ActionController::Base.helpers.number_to_currency(balance))
    end

    it "does not create entry with blank description" do
      expect {
        post admin_ledger_entries_path(ledger),
          params: { ledger_entry: { description: "", entry_type: "credit" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.not_to change(Ledger::Entry, :count)
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/ledgers/:ledger_id/entries/:id" do
    let!(:entry) { create(:ledger_entry, ledger: ledger) }

    it "destroys the entry" do
      expect {
        delete admin_ledger_entry_path(ledger, entry),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(Ledger::Entry, :count).by(-1)
    end

    it "responds with turbo stream" do
      delete admin_ledger_entry_path(ledger, entry),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
