require "rails_helper"

RSpec.describe "Admin::ScheduleEvents", type: :request do
  include ActiveJob::TestHelper

  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:role) do
    Role.create!(name: "schedule_event_manager", description: "Manage schedule events").tap do |r|
      r.permissions.create!(resource: "Location",      action: "show")
      r.permissions.create!(resource: "ScheduleEvent", action: "show")
      r.permissions.create!(resource: "ScheduleEvent", action: "create")
      r.permissions.create!(resource: "ScheduleEvent", action: "update")
      r.permissions.create!(resource: "ScheduleEvent", action: "destroy")
    end
  end

  let(:user)     { create(:user, role: role) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location, name: "Test Schedule") }
  let!(:event) do
    ScheduleEvent.create!(
      schedule:  schedule,
      uid:       "evt-1",
      summary:   "Morning Yoga",
      starts_at: Time.utc(2026, 6, 1, 9, 0),
      ends_at:   Time.utc(2026, 6, 1, 10, 0),
      all_day:   false
    )
  end

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/schedules/:schedule_id/schedule_events/new" do
    it "returns 200" do
      get new_admin_location_schedule_schedule_event_path(location, schedule)

      expect(response).to have_http_status(:ok)
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get new_admin_location_schedule_schedule_event_path(location, schedule)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/locations/:location_hashid/schedules/:schedule_id/schedule_events" do
    let(:valid_params) do
      {
        schedule_event: {
          summary:   "Evening Class",
          starts_at: "2026-07-01 18:00",
          ends_at:   "2026-07-01 19:00",
          all_day:   false
        }
      }
    end

    it "creates a schedule event" do
      expect {
        post admin_location_schedule_schedule_events_path(location, schedule), params: valid_params
      }.to change(ScheduleEvent, :count).by(1)
    end

    it "redirects to the schedule page with a notice" do
      post admin_location_schedule_schedule_events_path(location, schedule), params: valid_params

      expect(response).to redirect_to(admin_location_schedule_path(location, schedule))
      expect(flash[:notice]).to eq("Event added.")
    end

    it "stores the correct summary" do
      post admin_location_schedule_schedule_events_path(location, schedule), params: valid_params

      expect(ScheduleEvent.last.summary).to eq("Evening Class")
    end

    context "when the user lacks the create permission" do
      let(:role) do
        Role.create!(name: "schedule_read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Location",      action: "show")
          r.permissions.create!(resource: "ScheduleEvent", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          post admin_location_schedule_schedule_events_path(location, schedule), params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/.../schedule_events/:id/edit" do
    it "returns 200" do
      get edit_admin_location_schedule_schedule_event_path(location, schedule, event)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "PATCH /admin/.../schedule_events/:id" do
    it "updates the event summary" do
      patch admin_location_schedule_schedule_event_path(location, schedule, event),
            params: { schedule_event: { summary: "Updated Summary" } }

      expect(event.reload.summary).to eq("Updated Summary")
    end

    it "redirects to the schedule page with a notice" do
      patch admin_location_schedule_schedule_event_path(location, schedule, event),
            params: { schedule_event: { summary: "Updated Summary" } }

      expect(response).to redirect_to(admin_location_schedule_path(location, schedule))
      expect(flash[:notice]).to eq("Event updated.")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        patch admin_location_schedule_schedule_event_path(location, schedule, event),
              params: { schedule_event: { summary: "Hacked" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /admin/.../schedule_events/:id" do
    it "destroys the event" do
      expect {
        delete admin_location_schedule_schedule_event_path(location, schedule, event)
      }.to change(ScheduleEvent, :count).by(-1)
    end

    it "redirects to the schedule page with a notice" do
      delete admin_location_schedule_schedule_event_path(location, schedule, event)

      expect(response).to redirect_to(admin_location_schedule_path(location, schedule))
      expect(flash[:notice]).to eq("Event deleted.")
    end

    context "when the user lacks the destroy permission" do
      let(:role) do
        Role.create!(name: "schedule_read_only", description: "Read only").tap do |r|
          r.permissions.create!(resource: "Location",      action: "show")
          r.permissions.create!(resource: "ScheduleEvent", action: "show")
        end
      end

      it "raises Pundit::NotAuthorizedError" do
        expect {
          delete admin_location_schedule_schedule_event_path(location, schedule, event)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
