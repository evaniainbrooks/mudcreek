class Admin::SchedulesController < Admin::BaseController
  before_action :set_location
  before_action :set_schedule, only: [:show, :destroy]

  def show
    @events = @schedule.schedule_events.ordered
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
                  notice: "Schedule created.#{ ' Importing events in the background.' if @schedule.source_url.present? }"
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @schedule.destroy!
    redirect_to admin_location_path(@location, anchor: "schedules-pane"), notice: "Schedule deleted."
  end

  private

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
