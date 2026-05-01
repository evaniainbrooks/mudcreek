require "rails_helper"

RSpec.describe "Admin::Disciplines", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, features: { ranks: true })
  end

  let(:role) do
    Role.create!(name: "discipline_manager", description: "Manage disciplines").tap do |r|
      r.permissions.create!(resource: "Discipline", action: "index")
      r.permissions.create!(resource: "Discipline", action: "show")
      r.permissions.create!(resource: "Discipline", action: "create")
      r.permissions.create!(resource: "Discipline", action: "update")
      r.permissions.create!(resource: "Discipline", action: "destroy")
      r.permissions.create!(resource: "Rank",       action: "create")
      r.permissions.create!(resource: "Rank",       action: "update")
      r.permissions.create!(resource: "Rank",       action: "destroy")
    end
  end

  let(:user)        { create(:user, role: role) }
  let!(:discipline) { create(:discipline, name: "Brazilian Jiu-Jitsu") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/disciplines" do
    it "returns 200 and lists the discipline" do
      get admin_disciplines_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Brazilian Jiu-Jitsu")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_disciplines_path

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the index permission" do
      let(:role) { Role.create!(name: "no_disciplines", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect { get admin_disciplines_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/disciplines/:id" do
    it "returns 200 and shows the discipline" do
      get admin_discipline_path(discipline)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Brazilian Jiu-Jitsu")
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/disciplines/new" do
    it "returns 200" do
      get new_admin_discipline_path

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/disciplines" do
    it "creates the discipline and redirects to show" do
      expect {
        post admin_disciplines_path, params: { discipline: { name: "Wrestling" } }
      }.to change(Discipline, :count).by(1)

      expect(response).to redirect_to(admin_discipline_path(Discipline.last))
    end

    it "re-renders new with unprocessable_content on blank name" do
      post admin_disciplines_path, params: { discipline: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders new with unprocessable_content on duplicate name" do
      post admin_disciplines_path, params: { discipline: { name: "Brazilian Jiu-Jitsu" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_disciplines_path, params: { discipline: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/disciplines/:id/edit" do
    it "returns 200" do
      get edit_admin_discipline_path(discipline)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Brazilian Jiu-Jitsu")
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/disciplines/:id" do
    it "updates the discipline name and redirects to show" do
      patch admin_discipline_path(discipline), params: { discipline: { name: "Judo" } }

      expect(discipline.reload.name).to eq("Judo")
      expect(response).to redirect_to(admin_discipline_path(discipline))
    end

    it "re-renders edit with unprocessable_content on blank name" do
      patch admin_discipline_path(discipline), params: { discipline: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(discipline.reload.name).to eq("Brazilian Jiu-Jitsu")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_discipline_path(discipline), params: { discipline: { name: "Blocked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/disciplines/:id" do
    it "destroys the discipline and redirects to index" do
      expect {
        delete admin_discipline_path(discipline)
      }.to change(Discipline, :count).by(-1)

      expect(response).to redirect_to(admin_disciplines_path)
    end

    it "destroys associated ranks" do
      create(:rank, discipline: discipline)

      expect {
        delete admin_discipline_path(discipline)
      }.to change(Rank, :count).by(-1)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_discipline_path(discipline)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/disciplines/:discipline_id/ranks" do
    it "creates a rank and redirects to the discipline" do
      expect {
        post admin_discipline_ranks_path(discipline), params: { rank: { name: "White", position: 1 } }
      }.to change(Rank, :count).by(1)

      expect(response).to redirect_to(admin_discipline_path(discipline))
    end

    it "redirects with alert on blank name" do
      post admin_discipline_ranks_path(discipline), params: { rank: { name: "", position: 1 } }

      expect(response).to redirect_to(admin_discipline_path(discipline))
      expect(flash[:alert]).to be_present
    end

    it "redirects with alert on missing position" do
      post admin_discipline_ranks_path(discipline), params: { rank: { name: "White", position: "" } }

      expect(response).to redirect_to(admin_discipline_path(discipline))
      expect(flash[:alert]).to be_present
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_discipline_ranks_path(discipline), params: { rank: { name: "White", position: 1 } }

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "no_rank_create", description: "No rank create").tap do |r|
          r.permissions.create!(resource: "Discipline", action: "index")
          r.permissions.create!(resource: "Discipline", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_discipline_ranks_path(discipline), params: { rank: { name: "White", position: 1 } }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/disciplines/:discipline_id/ranks/:id/edit" do
    let!(:rank) { create(:rank, discipline: discipline, name: "White", position: 1) }

    it "returns 200 and shows the rank" do
      get edit_admin_discipline_rank_path(discipline, rank)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("White")
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/disciplines/:discipline_id/ranks/:id" do
    let!(:rank) { create(:rank, discipline: discipline, name: "White", position: 1) }

    it "updates the rank and redirects to the discipline" do
      patch admin_discipline_rank_path(discipline, rank), params: { rank: { name: "Blue", position: 2 } }

      expect(rank.reload.name).to eq("Blue")
      expect(rank.reload.position).to eq(2)
      expect(response).to redirect_to(admin_discipline_path(discipline))
    end

    it "re-renders edit with unprocessable_content on blank name" do
      patch admin_discipline_rank_path(discipline, rank), params: { rank: { name: "", position: 1 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(rank.reload.name).to eq("White")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_discipline_rank_path(discipline, rank), params: { rank: { name: "Blocked", position: 1 } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/disciplines/:discipline_id/ranks/:id" do
    let!(:rank) { create(:rank, discipline: discipline, name: "White", position: 1) }

    it "destroys the rank and redirects to the discipline" do
      expect {
        delete admin_discipline_rank_path(discipline, rank)
      }.to change(Rank, :count).by(-1)

      expect(response).to redirect_to(admin_discipline_path(discipline))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_discipline_rank_path(discipline, rank)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
