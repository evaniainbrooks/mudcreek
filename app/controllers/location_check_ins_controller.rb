class LocationCheckInsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  layout "checkin"

  before_action :set_location

  helper_method :exit_url

  def show
    @guest_checked_in = session.delete(:guest_checked_in)
    if Current.user && !bot_request?
      @check_in = @location.check_ins.build(user: Current.user)
      if @check_in.save
        session[:check_in_id] = @check_in.id
      end
    elsif Current.user
      @check_in = @location.check_ins.build(user: Current.user)
    else
      session[:return_to_after_authenticating] = request.url
      @check_in = @location.check_ins.build
      @guest_names = CheckIn.where.not(guest_name: nil)
                            .distinct
                            .order(:guest_name)
                            .pluck(:guest_name)
    end

    @today_schedule_events = load_today_schedule_events
  end

  def create
    return head :ok if bot_request?

    @check_in = @location.check_ins.build(guest_name: check_in_params[:guest_name])
    if @check_in.save
      session[:guest_checked_in] = @check_in.guest_name
      session[:check_in_id]      = @check_in.id
      redirect_to location_checkin_path(@location)
    else
      render :show, status: :unprocessable_content
    end
  end

  def update
    check_in = CheckIn.find_by(id: session.delete(:check_in_id))
    check_in&.update(schedule_event_id: params[:schedule_event_id].presence)
    redirect_to exit_url, allow_other_host: true
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
  end

  def check_in_params
    params.expect(check_in: [:guest_name])
  end

  def load_today_schedule_events
    schedule = @location.kiosk&.schedule
    return [] unless schedule

    ScheduleEventsCalendarService.new(schedule).today_events
  end

  def exit_url
    @location.kiosk&.checkin_exit_url.presence || root_path
  end
end
