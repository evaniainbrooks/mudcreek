class Admin::SchedulesController < Admin::BaseController
  before_action :set_location
  before_action :set_schedule, only: [:show, :edit, :update, :destroy]

  def show
    @day = params[:day].presence_in(%w[SU MO TU WE TH FR SA])
    @q   = params[:q].to_s.strip

    events = @schedule.schedule_events.ordered
    events = events.where("summary ILIKE ?", "%#{@q}%") if @q.present?

    if @day.present?
      @pagy, @events = nil, filter_by_day(events.to_a, @day)
    else
      @pagy, @events = pagy(events, limit: 100)
    end
  end

  def edit; end

  def update
    if @schedule.update(schedule_params)
      SyncScheduleJob.perform_later(@schedule.id) if @schedule.source_url.present? && @schedule.saved_change_to_source_url?
      redirect_to admin_location_schedule_path(@location, @schedule), notice: t(".notice")
    else
      flash.now[:alert] = @schedule.errors.full_messages.to_sentence
      render :show, status: :unprocessable_content
    end
  end

  def new
    @schedule = @location.schedules.build
    authorize(@schedule)
  end

  def create
    @schedule = @location.schedules.build(schedule_params)
    authorize(@schedule)

    if @schedule.save
      SyncScheduleJob.perform_later(@schedule.id) if @schedule.source_url.present?
      redirect_to admin_location_path(@location, anchor: "schedules-pane"),
                  notice: @schedule.source_url.present? ? t(".notice_importing") : t(".notice")
    else
      flash.now[:alert] = @schedule.errors.full_messages.to_sentence
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @schedule.destroy!
    redirect_to admin_location_path(@location, anchor: "schedules-pane"), notice: t(".notice")
  end

  private

  DAY_MAP = { "SU" => 0, "MO" => 1, "TU" => 2, "WE" => 3, "TH" => 4, "FR" => 5, "SA" => 6 }.freeze

  def filter_by_day(events, day_abbr)
    target_wday = DAY_MAP[day_abbr]
    return events unless target_wday

    events.select do |e|
      next false unless e.starts_at

      if e.rrule.present? && e.rrule.include?("BYDAY")
        byday_part = e.rrule.split(";").find { |p| p.start_with?("BYDAY=") }
        days = byday_part&.delete_prefix("BYDAY=")&.split(",")&.filter_map { |d| DAY_MAP[d[-2..]] } || []
        days.include?(target_wday)
      else
        e.starts_at.in_time_zone.wday == target_wday
      end
    end
  end

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_schedule
    @schedule = @location.schedules.find(params[:id])
    authorize(@schedule)
  end

  def schedule_params
    params.require(:schedule).permit(:name, :source_url, :shared)
  end
end
