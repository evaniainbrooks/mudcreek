class Admin::KiosksController < Admin::BaseController
  before_action :set_location
  before_action :set_kiosk

  def update
    @kiosk.logo.purge_later if params[:remove_logo].present?
    Array(params[:remove_background_ids]).each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      @kiosk.backgrounds.attachments.find_by(blob_id: blob.id)&.purge_later
    end
    new_backgrounds = params.dig(:kiosk, :backgrounds)&.reject(&:blank?)

    if @kiosk.update(kiosk_params)
      @kiosk.backgrounds.attach(new_backgrounds) if new_backgrounds.present?
      redirect_to admin_location_path(@location), notice: "Kiosk updated."
    else
      @qr_code      = @location.qr_code
      @schedules    = @location.schedules.ordered
      @members      = @location.users.order(:first_name, :last_name)
      @non_members  = User.where.not(id: @members.select(:id)).order(:first_name, :last_name)
      @announcements = @location.location_announcements.ordered.limit(5)
      @location.build_address unless @location.address
      render "admin/locations/show", status: :unprocessable_content
    end
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:location_hashid])
  end

  def set_kiosk
    @kiosk = @location.kiosk || @location.create_kiosk!
    authorize(@kiosk)
  end

  def kiosk_params
    params.require(:kiosk).permit(:logo, :message, :checkin_exit_url,
                                  :background_tint_opacity, :slide_timeout, :schedule_id,
                                  :member_birthdays)
  end
end
