class Admin::ScheduleCalendarsController < Admin::BaseController
  before_action :set_location
  before_action :set_schedule

  def show
    @calendar_view = params[:view].presence_in(%w[weekly daily]) || "weekly"
    authorize @schedule
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_schedule
    @schedule = @location.schedules.find(params[:schedule_id])
  end
end
