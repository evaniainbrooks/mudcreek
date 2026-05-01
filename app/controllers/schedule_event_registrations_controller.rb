class ScheduleEventRegistrationsController < ApplicationController
  before_action :require_authentication

  def create
    event   = ScheduleEvent.find(params[:schedule_event_id])
    date    = Date.parse(params[:occurs_on])
    session = ScheduleEventSession.find_or_create_by!(
      schedule_event: event,
      occurs_on: date,
      tenant: Current.tenant
    )

    pass = params[:schedule_event_pass_id].present? ?
             Current.user.schedule_event_passes.active.find(params[:schedule_event_pass_id]) : nil

    existing = Current.user.schedule_event_registrations
                           .joins(:schedule_event_session)
                           .find_by(schedule_event_session: session, status: :confirmed)

    if existing
      render turbo_stream: turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(event, :registration),
        partial: "schedule_event_registrations/button",
        locals: { event: event, occurs_on: date, registration: existing, session: session }
      )
      return
    end

    if event.capacity.present? && session.confirmed_registrations.count >= event.capacity
      render turbo_stream: turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(event, :registration),
        partial: "schedule_event_registrations/button",
        locals: { event:, occurs_on: date, registration: nil, session:, error: "This event is full." }
      )
      return
    end

    @registration = ScheduleEventRegistration.new(
      user: Current.user,
      schedule_event_session: session,
      schedule_event_pass: pass,
      tenant: Current.tenant,
      check_in_attributes: { user: Current.user, location: event.schedule.location, schedule_event: event }
    )

    if @registration.save
      render turbo_stream: turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(event, :registration),
        partial: "schedule_event_registrations/button",
        locals: { event:, occurs_on: date, registration: @registration, session: }
      )
    else
      render turbo_stream: turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(event, :registration),
        partial: "schedule_event_registrations/button",
        locals: { event:, occurs_on: date, registration: nil, session:, error: @registration.errors.full_messages.first }
      )
    end
  end

  def destroy
    @registration = Current.user.schedule_event_registrations.find(params[:id])
    event         = @registration.schedule_event_session.schedule_event
    occurs_on     = @registration.schedule_event_session.occurs_on
    event_session = @registration.schedule_event_session
    @registration.update!(status: :cancelled)

    render turbo_stream: turbo_stream.replace(
      ActionView::RecordIdentifier.dom_id(event, :registration),
      partial: "schedule_event_registrations/button",
      locals: { event: event, occurs_on: occurs_on, registration: nil, session: event_session }
    )
  end
end
