require "rails_helper"

RSpec.describe "Ledgers", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let!(:ledger) { create(:ledger, name: "Canteen") }

  # ------------------------------------------------------------------ #
  describe "GET /ledgers/:id" do
    it "returns 200 and shows the ledger name" do
      get ledger_path(ledger)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Canteen")
    end

    it "does not require authentication" do
      get ledger_path(ledger)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /ledgers/:id/entries" do
    let(:valid_params) do
      { ledger_entry: { description: "Coffee sales", entry_type: "credit", amount: "25.00" } }
    end

    it "creates an entry and redirects" do
      expect {
        post ledger_entries_path(ledger), params: valid_params
      }.to change(Ledger::Entry, :count).by(1)

      expect(response).to redirect_to(ledger_path(ledger))
    end

    it "creates a debit entry" do
      expect {
        post ledger_entries_path(ledger),
          params: { ledger_entry: { description: "Supplies", entry_type: "debit", amount: "10.00" } }
      }.to change(Ledger::Entry, :count).by(1)

      expect(Ledger::Entry.last.debit?).to be true
    end

    it "sets taxed when checked" do
      post ledger_entries_path(ledger),
        params: { ledger_entry: { description: "Sale", entry_type: "credit", amount: "50.00", taxed: "1" } }

      expect(Ledger::Entry.last.taxed?).to be true
    end

    it "does not require authentication" do
      post ledger_entries_path(ledger), params: valid_params

      expect(response).to redirect_to(ledger_path(ledger))
    end

    context "when the user is signed in" do
      let(:user) { create(:user) }

      before { post session_path, params: { email_address: user.email_address, password: "password" } }

      it "records the current user on the entry" do
        post ledger_entries_path(ledger), params: valid_params

        expect(Ledger::Entry.last.user).to eq(user)
      end
    end

    context "when the user is not signed in" do
      it "leaves user nil on the entry" do
        post ledger_entries_path(ledger), params: valid_params

        expect(Ledger::Entry.last.user).to be_nil
      end
    end

    context "with invalid params" do
      it "re-renders the form with unprocessable_content on blank description" do
        post ledger_entries_path(ledger),
          params: { ledger_entry: { description: "", entry_type: "credit", amount: "10.00" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Canteen")
      end

      it "does not create an entry" do
        expect {
          post ledger_entries_path(ledger),
            params: { ledger_entry: { description: "", entry_type: "credit" } }
        }.not_to change(Ledger::Entry, :count)
      end
    end
  end
end
