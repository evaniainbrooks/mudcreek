require "rails_helper"

RSpec.describe "Locations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true, features: { locations: true })
  end

  let!(:location) { create(:location, name: "Main Lobby", published: true) }

  before do
    allow(LocationCalendarService).to receive(:new).and_return(instance_double(LocationCalendarService, today_events: []))
  end

  # ------------------------------------------------------------------ #
  describe "GET /locations/:hashid" do
    it "returns 200" do
      get location_path(location)

      expect(response).to have_http_status(:ok)
    end

    it "renders the location name" do
      get location_path(location)

      expect(response.body).to include("Main Lobby")
    end

    it "renders the QR code check-in prompt" do
      get location_path(location)

      expect(response.body).to include("scan the QR code")
    end

    context "when the location is not published" do
      let!(:location) { create(:location, published: false) }

      it "returns 404" do
        get location_path(location)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the locations feature is disabled" do
      before { Current.tenant.update!(features: { locations: false }) }

      it "returns 404" do
        get location_path(location)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown hashid" do
      it "returns 404" do
        get location_path(hashid: "unknown")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when today has calendar events" do
      let(:events) do
        [
          instance_double(Icalendar::Event, summary: "Morning Class", dtstart: Time.zone.now, description: nil)
        ]
      end

      before do
        allow(LocationCalendarService).to receive(:new).and_return(
          instance_double(LocationCalendarService, today_events: events)
        )
      end

      it "renders the event summary" do
        get location_path(location)

        expect(response.body).to include("Morning Class")
      end
    end
  end
end
