class Admin::LocationAnnouncementsController < Admin::BaseController
  before_action :set_location
  before_action :set_announcement, only: [:show]

  def index
    authorize(LocationAnnouncement)
    @announcements = @location.location_announcements.ordered
  end

  def new
    @announcement = @location.location_announcements.build
    authorize(@announcement)
  end

  def create
    @announcement = @location.location_announcements.build(announcement_params)
    @announcement.sent_by = Current.user
    authorize(@announcement)

    if @announcement.save
      SendLocationAnnouncementJob.perform_later(@announcement.id)
      redirect_to admin_location_location_announcement_path(@location, @announcement),
                  notice: "Announcement queued for delivery."
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_announcement
    @announcement = @location.location_announcements.find(params[:id])
    authorize(@announcement)
  end

  def announcement_params
    params.require(:location_announcement).permit(:subject, :body)
  end
end
