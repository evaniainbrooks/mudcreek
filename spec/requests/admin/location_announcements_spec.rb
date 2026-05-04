require "rails_helper"

RSpec.describe "Admin::LocationAnnouncements", type: :request do
  include ActiveJob::TestHelper

  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  # LocationAnnouncement is not in Permission::RESOURCES, so tests use super_admin.
  let(:admin)    { create(:user, :super_admin) }
  let(:location) { create(:location, name: "Main Gym") }

  before { post session_path, params: { email_address: admin.email_address, password: "password" } }

  def build_announcement(attrs = {})
    LocationAnnouncement.create!(
      { location: location, sent_by: admin, subject: "Hello", body: "Body text" }.merge(attrs)
    )
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/location_announcements" do
    let!(:announcement) { build_announcement(subject: "Welcome back!") }

    it "returns 200" do
      get admin_location_location_announcements_path(location)

      expect(response).to have_http_status(:ok)
    end

    it "lists announcements for the location" do
      get admin_location_location_announcements_path(location)

      expect(response.body).to include("Welcome back!")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_location_location_announcements_path(location)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/location_announcements/new" do
    it "returns 200" do
      get new_admin_location_location_announcement_path(location)

      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ #
  describe "POST /admin/locations/:location_hashid/location_announcements" do
    let(:valid_params) do
      { location_announcement: { subject: "Grand Re-opening", body: "We're back!" } }
    end

    it "creates an announcement" do
      expect {
        post admin_location_location_announcements_path(location), params: valid_params
      }.to change(LocationAnnouncement, :count).by(1)
    end

    it "associates the announcement with the current admin as sent_by" do
      post admin_location_location_announcements_path(location), params: valid_params

      expect(LocationAnnouncement.last.sent_by).to eq(admin)
    end

    it "enqueues SendLocationAnnouncementJob" do
      expect {
        post admin_location_location_announcements_path(location), params: valid_params
      }.to have_enqueued_job(SendLocationAnnouncementJob)
    end

    it "redirects to the announcement show page with a notice" do
      post admin_location_location_announcements_path(location), params: valid_params

      announcement = LocationAnnouncement.last
      expect(response).to redirect_to(admin_location_location_announcement_path(location, announcement))
      expect(flash[:notice]).to eq("Announcement queued for delivery.")
    end

    context "with a blank subject" do
      it "returns unprocessable_content" do
        post admin_location_location_announcements_path(location),
             params: { location_announcement: { subject: "", body: "Body" } }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create an announcement" do
        expect {
          post admin_location_location_announcements_path(location),
               params: { location_announcement: { subject: "", body: "Body" } }
        }.not_to change(LocationAnnouncement, :count)
      end

      it "does not enqueue the delivery job" do
        expect {
          post admin_location_location_announcements_path(location),
               params: { location_announcement: { subject: "", body: "Body" } }
        }.not_to have_enqueued_job(SendLocationAnnouncementJob)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post admin_location_location_announcements_path(location), params: valid_params

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "GET /admin/locations/:location_hashid/location_announcements/:id" do
    let!(:announcement) { build_announcement(subject: "Member Update") }

    it "returns 200" do
      get admin_location_location_announcement_path(location, announcement)

      expect(response).to have_http_status(:ok)
    end

    it "displays the announcement subject" do
      get admin_location_location_announcement_path(location, announcement)

      expect(response.body).to include("Member Update")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        get admin_location_location_announcement_path(location, announcement)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
