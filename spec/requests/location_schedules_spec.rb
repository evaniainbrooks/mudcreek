require "rails_helper"

RSpec.describe "LocationSchedules", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, features: { locations: true })
  end

  let!(:location) { create(:location, name: "Studio A", published: true) }

  before do
    allow(LocationCalendarService).to receive(:new).and_return(
      instance_double(LocationCalendarService, week_events: {})
    )
  end

  # ------------------------------------------------------------------ #
  describe "GET /locations/:location_hashid/schedule" do
    it "returns 200" do
      get location_schedule_path(location)

      expect(response).to have_http_status(:ok)
    end

    it "renders the location name" do
      get location_schedule_path(location)

      expect(response.body).to include("Studio A")
    end

    it "renders day-of-week headers" do
      get location_schedule_path(location)

      %w[Sun Mon Tue Wed Thu Fri Sat].each do |day|
        expect(response.body).to include(day)
      end
    end

    it "renders hourly time labels from 6 AM to 9 PM" do
      get location_schedule_path(location)

      %w[6\ AM 7\ AM 8\ AM 9\ AM 10\ AM 11\ AM 12\ PM
         1\ PM 2\ PM 3\ PM 4\ PM 5\ PM 6\ PM 7\ PM 8\ PM 9\ PM].each do |label|
        expect(response.body).to include(label)
      end
    end

    context "when the location has calendar events this week" do
      let(:week_start) { Date.current.beginning_of_week(:sunday) }

      let(:event) do
        instance_double(
          Icalendar::Event,
          summary:  "Yoga Class",
          dtstart:  week_start.to_time + 9.hours,
          dtend:    week_start.to_time + 10.hours
        )
      end

      before do
        allow(LocationCalendarService).to receive(:new).and_return(
          instance_double(LocationCalendarService, week_events: { week_start => [ event ] })
        )
      end

      it "renders the event summary" do
        get location_schedule_path(location)

        expect(response.body).to include("Yoga Class")
      end

      it "renders the event start time" do
        get location_schedule_path(location)

        expect(response.body).to include("9:00 AM")
      end

      it "renders the event end time" do
        get location_schedule_path(location)

        expect(response.body).to include("10:00 AM")
      end
    end

    context "when the location is not published" do
      let!(:location) { create(:location, published: false) }

      it "returns 404" do
        get location_schedule_path(location)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the locations feature is disabled" do
      before { Current.tenant.update!(features: { locations: false }) }

      it "returns 404" do
        get location_schedule_path(location)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown hashid" do
      it "returns 404" do
        get location_schedule_path(location_hashid: "unknown")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /schedule" do
    context "when a default published location exists" do
      let!(:location) { create(:location, name: "Studio A", published: true, default: true) }

      it "returns 200" do
        get "/schedule"

        expect(response).to have_http_status(:ok)
      end

      it "renders the location name" do
        get "/schedule"

        expect(response.body).to include("Studio A")
      end
    end

    context "when no default location exists" do
      it "returns 404" do
        get "/schedule"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the default location is not published" do
      let!(:location) { create(:location, published: false, default: true) }

      it "returns 404" do
        get "/schedule"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the locations feature is disabled" do
      let!(:location) { create(:location, published: true, default: true) }

      before { Current.tenant.update!(features: { locations: false }) }

      it "returns 404" do
        get "/schedule"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
