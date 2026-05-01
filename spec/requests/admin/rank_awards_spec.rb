require "rails_helper"

RSpec.describe "Admin::RankAwards", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, features: { ranks: true })
  end

  let(:role) do
    Role.create!(name: "rank_manager", description: "Manage rank awards").tap do |r|
      r.permissions.create!(resource: "User",      action: "show")
      r.permissions.create!(resource: "RankAward", action: "create")
      r.permissions.create!(resource: "RankAward", action: "destroy")
    end
  end

  let(:admin)      { create(:user, role: role) }
  let(:member)     { create(:user) }
  let(:discipline) { create(:discipline, name: "Brazilian Jiu-Jitsu") }
  let!(:rank)      { create(:rank, discipline: discipline, name: "White", position: 1) }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "POST /admin/rank_awards" do
    let(:valid_params) do
      {
        rank_award: {
          rankable_type: "User",
          rankable_id:   member.id,
          rank_id:       rank.id,
          stripes:       0,
          awarded_at:    Date.current.to_s
        }
      }
    end

    it "creates a rank award for a user" do
      expect {
        post admin_rank_awards_path, params: valid_params
      }.to change(RankAward, :count).by(1)
    end

    it "redirects back with a notice on success" do
      post admin_rank_awards_path, params: valid_params,
        headers: { "HTTP_REFERER" => admin_user_path(member, tab: "ranks") }

      expect(response).to redirect_to(admin_user_path(member, tab: "ranks"))
      expect(flash[:notice]).to eq("Promotion recorded.")
    end

    it "sets awarded_by to the current admin" do
      post admin_rank_awards_path, params: valid_params

      expect(RankAward.last.awarded_by).to eq(admin)
    end

    context "for a kid" do
      let(:kid) { create(:kid, user: member) }

      it "creates a rank award for the kid" do
        expect {
          post admin_rank_awards_path, params: {
            rank_award: {
              rankable_type: "Kid",
              rankable_id:   kid.id,
              rank_id:       rank.id,
              stripes:       2,
              awarded_at:    Date.current.to_s
            }
          }
        }.to change(RankAward, :count).by(1)

        expect(RankAward.last.rankable).to eq(kid)
      end
    end

    context "with missing awarded_at" do
      it "redirects back with an alert" do
        post admin_rank_awards_path, params: {
          rank_award: {
            rankable_type: "User",
            rankable_id:   member.id,
            rank_id:       rank.id,
            stripes:       0,
            awarded_at:    ""
          }
        }

        expect(response).to be_redirect
        expect(flash[:alert]).to be_present
      end

      it "does not create a rank award" do
        expect {
          post admin_rank_awards_path, params: {
            rank_award: {
              rankable_type: "User",
              rankable_id:   member.id,
              rank_id:       rank.id,
              stripes:       0,
              awarded_at:    ""
            }
          }
        }.not_to change(RankAward, :count)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_rank_awards_path, params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the create permission" do
      let(:role) { Role.create!(name: "no_rank_awards", description: "No access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_rank_awards_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/rank_awards/:id" do
    let!(:award) { create(:rank_award, rankable: member, rank: rank, awarded_at: Date.current) }

    it "destroys the rank award" do
      expect {
        delete admin_rank_award_path(award)
      }.to change(RankAward, :count).by(-1)
    end

    it "redirects back with a notice" do
      delete admin_rank_award_path(award),
        headers: { "HTTP_REFERER" => admin_user_path(member, tab: "ranks") }

      expect(response).to redirect_to(admin_user_path(member, tab: "ranks"))
      expect(flash[:notice]).to eq("Promotion removed.")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete admin_rank_award_path(award)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "no_destroy", description: "No destroy").tap do |r|
          r.permissions.create!(resource: "RankAward", action: "create")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_rank_award_path(award)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
