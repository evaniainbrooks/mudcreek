require "rails_helper"

RSpec.describe "Admin::ScheduleCalendars", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, timezone: "Eastern Time (US & Canada)")
  end

  let(:role) do
    Role.create!(name: "schedule_viewer", description: "View schedules").tap do |r|
      r.permissions.create!(resource: "Location", action: "show")
      r.permissions.create!(resource: "Schedule", action: "show")
    end
  end

  let(:user)     { create(:user, role: role) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location, name: "Test Schedule") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/schedules/:schedule_id/calendar" do
    it "returns 200" do
      get admin_location_schedule_calendar_path(location, schedule)

      expect(response).to have_http_status(:ok)
    end

    it "defaults to the weekly view" do
      get admin_location_schedule_calendar_path(location, schedule)

      expect(response.body).to include("weekly")
    end

    it "accepts the daily view param" do
      get admin_location_schedule_calendar_path(location, schedule, view: "daily")

      expect(response).to have_http_status(:ok)
    end

    it "rejects unknown view params and falls back to weekly" do
      get admin_location_schedule_calendar_path(location, schedule, view: "unknown")

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_location_schedule_calendar_path(location, schedule)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_schedule", description: "No schedule access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          get admin_location_schedule_calendar_path(location, schedule)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
