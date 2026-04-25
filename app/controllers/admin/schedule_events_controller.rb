class Admin::ScheduleEventsController < Admin::BaseController
  before_action :set_location
  before_action :set_schedule
  before_action :set_event, only: [:edit, :update, :destroy]

  def new
    @event        = @schedule.schedule_events.build
    @rrule_params = RruleBuilderService.parse(nil)
    authorize(@event)
  end

  def create
    @event        = @schedule.schedule_events.build(event_params)
    @event.rrule  = RruleBuilderService.build(params.dig(:schedule_event, :recurrence))
    @rrule_params = RruleBuilderService.parse(@event.rrule)
    authorize(@event)

    if @event.save
      redirect_to admin_location_schedule_path(@location, @schedule), notice: "Event added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @rrule_params = RruleBuilderService.parse(@event.rrule)
  end

  def update
    @event.assign_attributes(event_params)
    @event.rrule  = RruleBuilderService.build(params.dig(:schedule_event, :recurrence))
    @rrule_params = RruleBuilderService.parse(@event.rrule)

    if @event.save
      redirect_to admin_location_schedule_path(@location, @schedule), notice: "Event updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @event.destroy!
    redirect_to admin_location_schedule_path(@location, @schedule), notice: "Event deleted."
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_schedule
    @schedule = @location.schedules.find(params[:schedule_id])
  end

  def set_event
    @event = @schedule.schedule_events.find(params[:id])
    authorize(@event)
  end

  def event_params
    params.require(:schedule_event).permit(:summary, :starts_at, :ends_at, :all_day, :photo)
  end
end
