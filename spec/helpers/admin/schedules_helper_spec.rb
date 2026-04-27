require "rails_helper"

RSpec.describe Admin::SchedulesHelper, type: :helper do
  let(:tenant)   { create(:tenant) }
  let(:location) { create(:location) }
  let(:schedule) { location.schedules.create!(name: "Test Schedule") }

  before { Current.tenant = tenant }
  after  { Current.tenant = nil }

  describe "#schedule_events_table" do
    let(:event) do
      schedule.schedule_events.create!(
        summary:   "Morning Yoga",
        starts_at: Time.zone.parse("2026-05-01 08:00"),
        ends_at:   Time.zone.parse("2026-05-01 09:00"),
        uid:       SecureRandom.uuid
      )
    end

    subject(:html) { Capybara.string(helper.schedule_events_table([event], location, schedule, nil).to_s) }

    it "renders a table" do
      expect(html).to have_css("table")
    end

    it "renders each column header" do
      %w[Summary Starts Ends Recurrence Bookable].each do |header|
        expect(html).to have_css("th", text: header)
      end
    end

    it "renders a row for the event" do
      expect(html).to have_css("tbody tr", count: 1)
    end

    it "links the summary to the edit path" do
      expect(html).to have_link("Morning Yoga",
        href: edit_admin_location_schedule_schedule_event_path(location, schedule, event))
    end

    it "renders the start time" do
      expect(html).to have_text("May 1, 2026")
    end

    it "renders a delete button" do
      expect(html).to have_css("form[action='#{admin_location_schedule_schedule_event_path(location, schedule, event)}']")
    end

    context "when the event has no summary" do
      before { event.update_columns(summary: nil) }

      it "renders a 'No title' placeholder" do
        expect(html).to have_css("em", text: "No title")
      end
    end

    context "when the event is all-day" do
      before { event.update_columns(all_day: true) }

      it "renders a check in the All Day column" do
        expect(html).to have_css("td i.bi-check-lg")
      end
    end

    context "when the event is bookable" do
      before { event.update_columns(bookable: true) }

      it "renders a check in the Bookable column" do
        expect(html).to have_css("td i.bi-check-lg")
      end
    end

    context "when the event has an rrule" do
      before { event.update_columns(rrule: "FREQ=WEEKLY;BYDAY=TH") }

      it "renders the rrule in a code tag" do
        expect(html).to have_css("code", text: "FREQ=WEEKLY;BYDAY=TH")
      end
    end

    context "with an empty events list" do
      subject(:result) { helper.schedule_events_table([], location, schedule, nil) }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "with a next page" do
      let(:pagy) { instance_double(Pagy, next: 2) }

      subject(:html) { Capybara.string(helper.schedule_events_table([event], location, schedule, pagy).to_s) }

      it "renders a Next link in the card footer" do
        expect(html).to have_css(".card-footer")
        expect(html).to have_link("Next",
          href: admin_location_schedule_path(location, schedule, page: 2))
      end
    end

    context "when on the last page" do
      let(:pagy) { instance_double(Pagy, next: nil) }

      subject(:html) { Capybara.string(helper.schedule_events_table([event], location, schedule, pagy).to_s) }

      it "does not render the card footer" do
        expect(html).not_to have_css(".card-footer")
      end
    end
  end
end
