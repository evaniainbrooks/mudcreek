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
      r.permissions.create!(resource: "Schedule", action: "create")
      r.permissions.create!(resource: "Schedule", action: "update")
      r.permissions.create!(resource: "Schedule", action: "destroy")
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

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/schedules/new" do
    it "returns 200 and renders the form" do
      get new_admin_location_schedule_path(location)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Schedule")
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/locations/:location_hashid/schedules" do
    context "with valid params" do
      it "creates the schedule and redirects to the location" do
        expect {
          post admin_location_schedules_path(location), params: { schedule: { name: "Morning Classes" } }
        }.to change(Schedule, :count).by(1)

        expect(response).to redirect_to(admin_location_path(location, anchor: "schedules-pane"))
      end

      it "sets a flash notice" do
        post admin_location_schedules_path(location), params: { schedule: { name: "Morning Classes" } }

        expect(flash[:notice]).to include("Schedule created")
      end

      it "enqueues SyncScheduleJob when source_url is present" do
        expect {
          post admin_location_schedules_path(location),
               params: { schedule: { name: "Remote Cal", source_url: "https://example.com/cal.ics" } }
        }.to have_enqueued_job(SyncScheduleJob)
      end

      it "does not enqueue SyncScheduleJob when source_url is blank" do
        expect {
          post admin_location_schedules_path(location),
               params: { schedule: { name: "Local Cal" } }
        }.not_to have_enqueued_job(SyncScheduleJob)
      end
    end

  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/locations/:location_hashid/schedules/:id" do
    context "with valid params" do
      it "redirects to the schedule show page" do
        patch admin_location_schedule_path(location, schedule),
              params: { schedule: { name: "Updated Name" } }

        expect(response).to redirect_to(admin_location_schedule_path(location, schedule))
      end

      it "updates the schedule name" do
        patch admin_location_schedule_path(location, schedule),
              params: { schedule: { name: "Updated Name" } }

        expect(schedule.reload.name).to eq("Updated Name")
      end

      it "sets a flash notice" do
        patch admin_location_schedule_path(location, schedule),
              params: { schedule: { name: "Updated Name" } }

        expect(flash[:notice]).to eq("Schedule updated.")
      end

      it "enqueues SyncScheduleJob when source_url changes" do
        expect {
          patch admin_location_schedule_path(location, schedule),
                params: { schedule: { source_url: "https://example.com/new.ics" } }
        }.to have_enqueued_job(SyncScheduleJob).with(schedule.id)
      end

      it "does not enqueue SyncScheduleJob when source_url is unchanged" do
        schedule.update!(source_url: "https://example.com/cal.ics")
        expect {
          patch admin_location_schedule_path(location, schedule),
                params: { schedule: { name: "New Name" } }
        }.not_to have_enqueued_job(SyncScheduleJob)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_location_schedule_path(location, schedule),
              params: { schedule: { name: "Hacked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/locations/:location_hashid/schedules/:id" do
    before { schedule }

    it "destroys the schedule" do
      expect {
        delete admin_location_schedule_path(location, schedule)
      }.to change(Schedule, :count).by(-1)
    end

    it "redirects to the location page" do
      delete admin_location_schedule_path(location, schedule)

      expect(response).to redirect_to(admin_location_path(location, anchor: "schedules-pane"))
    end

    it "sets a flash notice" do
      delete admin_location_schedule_path(location, schedule)

      expect(flash[:notice]).to eq("Schedule deleted.")
    end
  end
end
