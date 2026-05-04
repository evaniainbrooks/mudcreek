require "rails_helper"

RSpec.describe "Admin::ScheduleEventSessions", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "schedule_viewer", description: "View schedule events").tap do |r|
      r.permissions.create!(resource: "Location",      action: "show")
      r.permissions.create!(resource: "ScheduleEvent", action: "show")
    end
  end

  let(:user)     { create(:user, role: role) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location, name: "Test Schedule") }
  let(:event) do
    ScheduleEvent.create!(
      schedule:  schedule,
      uid:       "ses-evt-1",
      summary:   "Morning Class",
      starts_at: Time.utc(2026, 6, 1, 9, 0),
      ends_at:   Time.utc(2026, 6, 1, 10, 0),
      all_day:   false
    )
  end

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/.../schedule_events/:schedule_event_id/schedule_event_sessions/:occurs_on" do
    let(:occurs_on) { "2026-06-01" }

    it "returns 200" do
      get admin_location_schedule_schedule_event_schedule_event_session_path(
        location, schedule, event, occurs_on
      )

      expect(response).to have_http_status(:ok)
    end

    it "creates a ScheduleEventSession record for the given date if one does not exist" do
      expect {
        get admin_location_schedule_schedule_event_schedule_event_session_path(
          location, schedule, event, occurs_on
        )
      }.to change(ScheduleEventSession, :count).by(1)
    end

    it "is idempotent — does not create duplicate sessions on repeated requests" do
      2.times do
        get admin_location_schedule_schedule_event_schedule_event_session_path(
          location, schedule, event, occurs_on
        )
      end

      expect(ScheduleEventSession.where(schedule_event: event, occurs_on: occurs_on).count).to eq(1)
    end

    it "shows the event summary" do
      get admin_location_schedule_schedule_event_schedule_event_session_path(
        location, schedule, event, occurs_on
      )

      expect(response.body).to include("Morning Class")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_location_schedule_schedule_event_schedule_event_session_path(
          location, schedule, event, occurs_on
        )

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when the user lacks the show permission" do
      let(:role) { Role.create!(name: "no_schedule", description: "No schedule access") }

      it "raises Pundit::NotAuthorizedError" do
        expect {
          get admin_location_schedule_schedule_event_schedule_event_session_path(
            location, schedule, event, occurs_on
          )
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
