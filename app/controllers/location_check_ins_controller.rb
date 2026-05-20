class LocationCheckInsController < ApplicationController
  include LocationFeatureGated

  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token, only: %i[create update]
  layout "checkin"

  before_action :set_location
  before_action :activate_loop_mode

  helper_method :exit_url, :checkin_loop?

  def show
    @guest_checked_in = session.delete(:guest_checked_in)
    @today_schedule_events = load_today_schedule_events

    if Current.user && !bot_request?
      @check_in = @location.check_ins.build(user: Current.user, source: :kiosk)
      if @check_in.save
        if @today_schedule_events.one?
          apply_event(@check_in, @today_schedule_events.first)
          @today_schedule_events = []
        else
          session[:check_in_id] = @check_in.id
        end
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

    if @guest_checked_in && @today_schedule_events.one?
      check_in = CheckIn.find_by(id: session.delete(:check_in_id))
      apply_event(check_in, @today_schedule_events.first)
      session[:guest_name_for_prompt] = @guest_checked_in
      redirect_to guest_prompt_location_checkin_path(@location) and return
    end
  end

  def create
    return head :ok if bot_request?

    @check_in = @location.check_ins.build(guest_name: check_in_params[:guest_name], source: :kiosk)
    if @check_in.save
      session[:guest_checked_in] = @check_in.guest_name
      session[:check_in_id]      = @check_in.id
      redirect_to location_checkin_path(@location)
    else
      render :show, status: :unprocessable_content
    end
  end

  def update
    check_in      = CheckIn.find_by(id: session.delete(:check_in_id))
    event_id      = params[:schedule_event_id].presence
    registration  = resolve_registration(check_in, event_id)
    check_in&.update(schedule_event_id: event_id, schedule_event_registration: registration)

    if Current.user
      redirect_to exit_url, allow_other_host: true
    else
      session[:guest_name_for_prompt] = check_in&.guest_name
      redirect_to guest_prompt_location_checkin_path(@location)
    end
  end

  def guest_prompt
    @kiosk = @location.kiosk
    @guest_name = session.delete(:guest_name_for_prompt)
  end

  def purchase_drop_in
    kiosk   = @location.kiosk
    listing = kiosk&.drop_in_pass_listing
    return redirect_to guest_prompt_location_checkin_path(@location) unless listing

    token = session[:guest_cart_token] ||= SecureRandom.uuid
    scope = CartItem.where(guest_cart_token: token)

    AddSaleCartItemService.call(
      listing:            listing,
      cart_items_scope:   scope,
      requested_quantity: 1
    )

    redirect_to cart_path
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid], published: true)
  end

  def check_in_params
    params.expect(check_in: [:guest_name])
  end

  def apply_event(check_in, event)
    registration = resolve_registration(check_in, event.id.to_s)
    check_in&.update(schedule_event_id: event.id, schedule_event_registration: registration)
  end

  def resolve_registration(check_in, event_id)
    return nil unless check_in&.user_id && event_id
    ScheduleEventRegistration
      .joins(:schedule_event_session)
      .find_by(
        user_id: check_in.user_id,
        status: :confirmed,
        schedule_event_sessions: { schedule_event_id: event_id, occurs_on: Date.current }
      )
  end

  def load_today_schedule_events
    schedule = @location.kiosk&.schedule
    return [] unless schedule

    ScheduleEventsCalendarService.new(schedule).today_events
  end

  def activate_loop_mode
    session[:checkin_loop] = true if params[:loop].present?
  end

  def checkin_loop?
    session[:checkin_loop]
  end

  def exit_url
    if checkin_loop?
      location_checkin_path(@location)
    else
      @location.kiosk&.checkin_exit_url.presence || root_path
    end
  end
end
