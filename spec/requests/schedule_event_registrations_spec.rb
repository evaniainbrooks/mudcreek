require "rails_helper"

RSpec.describe "ScheduleEventRegistrations", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:user)     { create(:user) }
  let(:location) { create(:location) }
  let(:schedule) { Schedule.create!(location: location, name: "Test Schedule", tenant: Current.tenant) }
  let(:event) do
    ScheduleEvent.create!(
      schedule: schedule,
      uid:      SecureRandom.uuid,
      summary:  "Morning Class",
      tenant:   Current.tenant
    )
  end
  let(:occurs_on) { Date.current.to_s }

  before { post session_path, params: { email_address: user.email_address, password: "password" } }

  # ------------------------------------------------------------------ #
  describe "POST /schedule_event_registrations" do
    def post_registration(extra_params = {})
      post schedule_event_registrations_path, params: {
        schedule_event_id: event.id,
        occurs_on:         occurs_on
      }.merge(extra_params)
    end

    it "creates a registration" do
      expect { post_registration }.to change(ScheduleEventRegistration, :count).by(1)
    end

    it "returns a turbo-stream response" do
      post_registration

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    it "creates an associated session for the date" do
      expect { post_registration }.to change(ScheduleEventSession, :count).by(1)
    end

    it "reuses an existing session on a second registration" do
      ScheduleEventSession.create!(schedule_event: event, occurs_on: Date.current, tenant: Current.tenant)

      expect { post_registration }.not_to change(ScheduleEventSession, :count)
    end

    context "when the user is already registered" do
      before do
        session = ScheduleEventSession.create!(schedule_event: event, occurs_on: Date.current, tenant: Current.tenant)
        ScheduleEventRegistration.create!(user: user, schedule_event_session: session, tenant: Current.tenant)
      end

      it "does not create a duplicate registration" do
        expect { post_registration }.not_to change(ScheduleEventRegistration, :count)
      end

      it "returns a turbo-stream response" do
        post_registration

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "when the event is at capacity" do
      let(:other_user) { create(:user) }
      let(:event) do
        ScheduleEvent.create!(
          schedule: schedule,
          uid:      SecureRandom.uuid,
          summary:  "Full Class",
          capacity: 1,
          tenant:   Current.tenant
        )
      end

      before do
        session = ScheduleEventSession.create!(schedule_event: event, occurs_on: Date.current, tenant: Current.tenant)
        ScheduleEventRegistration.create!(user: other_user, schedule_event_session: session, tenant: Current.tenant)
      end

      it "does not create a registration" do
        expect { post_registration }.not_to change(ScheduleEventRegistration, :count)
      end

      it "returns a turbo-stream response" do
        post_registration

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "with a schedule event pass" do
      let(:pass) do
        ScheduleEventPass.create!(user: user, credits_remaining: 5, tenant: Current.tenant)
      end

      it "associates the pass with the registration" do
        post_registration(schedule_event_pass_id: pass.id)

        expect(ScheduleEventRegistration.last.schedule_event_pass).to eq(pass)
      end
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        post_registration

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe "DELETE /schedule_event_registrations/:id" do
    let!(:event_session) do
      ScheduleEventSession.create!(schedule_event: event, occurs_on: Date.current, tenant: Current.tenant)
    end
    let!(:registration) do
      ScheduleEventRegistration.create!(user: user, schedule_event_session: event_session, tenant: Current.tenant)
    end

    it "cancels the registration" do
      delete schedule_event_registration_path(registration)

      expect(registration.reload.status).to eq("cancelled")
    end

    it "returns a turbo-stream response" do
      delete schedule_event_registration_path(registration)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to sign in" do
        delete schedule_event_registration_path(registration)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
