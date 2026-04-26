class Admin::ScheduleEventSessionsController < Admin::BaseController
  before_action :set_location
  before_action :set_schedule
  before_action :set_event
  before_action :set_session

  def show
    @registrations = @session.schedule_event_registrations.confirmed
                              .includes(:user, :schedule_event_pass)
                              .order(created_at: :asc)
    @available_users = User.activated.order(:email_address)
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_schedule
    @schedule = @location.schedules.find(params[:schedule_id])
  end

  def set_event
    @event = @schedule.schedule_events.find(params[:schedule_event_id])
    authorize(@event, :show?)
  end

  def set_session
    @session = ScheduleEventSession.find_or_create_by!(
      schedule_event: @event,
      occurs_on: Date.parse(params[:occurs_on]),
      tenant: Current.tenant
    )
  end
end
