require "rails_helper"

RSpec.describe "Admin::Schedules", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, timezone: "Eastern Time (US & Canada)")
  end

  let(:role) do
    Role.create!(name: "schedule_manager", description: "Manage schedules").tap do |r|
      r.permissions.create!(resource: "Location", action: "show")
      r.permissions.create!(resource: "Schedule", action: "show")
    end
  end

  let(:user)     { create(:user, role: role) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location, name: "Test Schedule") }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  describe "GET /admin/locations/:location_hashid/schedules/:id" do
    it "returns 200" do
      get admin_location_schedule_path(location, schedule)

      expect(response).to have_http_status(:ok)
    end

    context "with a timed event stored in UTC" do
      it "displays starts_at in the tenant timezone" do
        # 3:00 AM UTC = 11:00 PM Eastern (previous day)
        ScheduleEvent.create!(
          schedule: schedule,
          uid:      "tz-test-1",
          summary:  "Midnight Meeting",
          starts_at: Time.utc(2026, 5, 1, 3, 0, 0),
          ends_at:   Time.utc(2026, 5, 1, 4, 0, 0),
          all_day:  false
        )

        get admin_location_schedule_path(location, schedule)

        # 3 AM UTC = 11 PM Eastern — should show Apr 30 11:00 PM, NOT May 1
        expect(response.body).to include("Apr 30, 2026")
        expect(response.body).to include("11:00 PM")
      end
    end

    context "with view=weekly and a timed event stored in UTC" do
      it "renders the calendar tab without error" do
        ScheduleEvent.create!(
          schedule:  schedule,
          uid:       "cal-tz-1",
          summary:   "Morning Standup",
          starts_at: Time.utc(2026, 5, 1, 14, 0, 0),
          ends_at:   Time.utc(2026, 5, 1, 14, 30, 0),
          all_day:   false
        )

        get admin_location_schedule_path(location, schedule, view: "weekly")

        expect(response).to have_http_status(:ok)
      end
    end

    context "with an all-day event" do
      it "displays the stored date without timezone shift" do
        ScheduleEvent.create!(
          schedule:  schedule,
          uid:       "allday-tz-1",
          summary:   "Company Holiday",
          starts_at: Time.utc(2026, 12, 25, 0, 0, 0),
          ends_at:   Time.utc(2026, 12, 26, 0, 0, 0),
          all_day:   true
        )

        get admin_location_schedule_path(location, schedule)

        # All-day date must not shift when tenant is UTC-5
        expect(response.body).to include("Dec 25, 2026")
      end
    end
  end
end
