require "rails_helper"

RSpec.describe "Admin::Lots::Settlements", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "settlement_manager", description: "Manage settlements").tap do |r|
      r.permissions.create!(resource: "Settlement", action: "show")
      r.permissions.create!(resource: "Settlement", action: "update")
    end
  end

  let(:user) { create(:user, role: role) }
  let!(:lot)  { create(:lot) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/lots/:lot_hashid/settlement" do
    it "returns 200" do
      get admin_lot_settlement_path(lot)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_lot_settlement_path(lot)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_settlement", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_lot_settlement_path(lot) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/lots/:lot_hashid/settlement/pay" do
    context "when no settlement exists" do
      it "redirects with an alert" do
        post pay_admin_lot_settlement_path(lot)

        expect(response).to redirect_to(admin_lot_settlement_path(lot))
        expect(flash[:alert]).to be_present
      end
    end

    context "when a settlement exists" do
      let!(:settlement) do
        s = lot.create_settlement!
        s.settlement_line_items.create!(line_item_type: :hammer_price, amount_cents: 10_000, description: "Sale price")
        s
      end

      it "marks the lot as paid" do
        post pay_admin_lot_settlement_path(lot)

        expect(lot.reload.state).to eq("paid")
      end

      it "sets paid_at on the lot" do
        post pay_admin_lot_settlement_path(lot)

        expect(lot.reload.paid_at).to be_present
      end

      it "redirects to the settlement page with a notice" do
        post pay_admin_lot_settlement_path(lot)

        expect(response).to redirect_to(admin_lot_settlement_path(lot))
        expect(flash[:notice]).to be_present
      end

      it "enqueues a payout email" do
        expect { post pay_admin_lot_settlement_path(lot) }.to have_enqueued_mail(LotMailer, :payout_sent)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_settlement", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Settlement", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect { post pay_admin_lot_settlement_path(lot) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
