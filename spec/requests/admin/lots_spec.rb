require "rails_helper"

RSpec.describe "Admin::Lots", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "lot_manager", description: "Manage lots").tap do |r|
      r.permissions.create!(resource: "Lot", action: "index")
      r.permissions.create!(resource: "Lot", action: "create")
      r.permissions.create!(resource: "Lot", action: "update")
      r.permissions.create!(resource: "Lot", action: "destroy")
    end
  end

  let(:owner) { create(:user) }
  let(:user)  { create(:user, role: role) }
  let!(:lot)  { create(:lot, owner: owner) }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/lots" do
    it "returns 200" do
      get admin_lots_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the lot name in the response" do
      get admin_lots_path

      expect(response.body).to include(lot.name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        get admin_lots_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_lots", description: "No lot access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_lots_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/lots" do
    context "with valid params" do
      let(:valid_params) { { lot: { name: "Lot A", owner_id: owner.id } } }

      it "creates a new lot" do
        expect {
          post admin_lots_path, params: valid_params
        }.to change(Lot, :count).by(1)
      end

      it "redirects to the index with a notice including the lot name" do
        post admin_lots_path, params: valid_params

        expect(response).to redirect_to(admin_lots_path)
        expect(flash[:notice]).to include("Lot A")
      end
    end

    context "with a missing name" do
      it "does not create a lot" do
        expect {
          post admin_lots_path, params: { lot: { name: "", owner_id: owner.id } }
        }.not_to change(Lot, :count)
      end

      it "re-renders the index with unprocessable entity status" do
        post admin_lots_path, params: { lot: { name: "", owner_id: owner.id } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        post admin_lots_path, params: { lot: { name: "Lot A", owner_id: owner.id } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "read_only_lots", description: "Read-only lot access").tap do |r|
          r.permissions.create!(resource: "Lot", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_lots_path, params: { lot: { name: "Lot A", owner_id: owner.id } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/lots/:id" do
    context "updating the name" do
      it "changes the lot name" do
        patch admin_lot_path(lot), params: { lot: { name: "Renamed Lot" } }

        expect(lot.reload.name).to eq("Renamed Lot")
      end

      it "redirects to the index for HTML requests" do
        patch admin_lot_path(lot), params: { lot: { name: "Renamed Lot" } }

        expect(response).to redirect_to(admin_lots_path)
      end

      it "responds with a turbo stream for turbo requests" do
        patch admin_lot_path(lot),
          params: { lot: { name: "Renamed Lot" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "updating the owner" do
      let(:new_owner) { create(:user) }

      it "changes the owner" do
        patch admin_lot_path(lot), params: { lot: { owner_id: new_owner.id } }

        expect(lot.reload.owner).to eq(new_owner)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        patch admin_lot_path(lot), params: { lot: { name: "Renamed Lot" } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the update permission" do
      let(:role) do
        Role.create!(name: "read_only_lots", description: "Read-only lot access").tap do |r|
          r.permissions.create!(resource: "Lot", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          patch admin_lot_path(lot), params: { lot: { name: "Renamed Lot" } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/lots/:id" do
    it "destroys the lot" do
      expect {
        delete admin_lot_path(lot)
      }.to change(Lot, :count).by(-1)
    end

    it "redirects to the index with a notice including the lot name" do
      name = lot.name
      delete admin_lot_path(lot)

      expect(response).to redirect_to(admin_lots_path)
      expect(flash[:notice]).to include(name)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to the sign-in page" do
        delete admin_lot_path(lot)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "read_only_lots", description: "Read-only lot access").tap do |r|
          r.permissions.create!(resource: "Lot", action: "index")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_lot_path(lot)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
