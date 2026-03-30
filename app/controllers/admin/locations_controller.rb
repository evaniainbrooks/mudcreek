class Admin::LocationsController < Admin::BaseController
  before_action :set_location, only: %i[show edit update destroy]

  def index
    authorize(Location)
    @pagy, @locations = pagy(:keyset, Location.ordered)
  end

  def show
    @qr_code           = @location.qr_code
    @total_check_ins   = @location.check_ins.count
    @today_check_ins   = @location.check_ins.today.count
    @week_check_ins    = @location.check_ins.this_week.count
    @month_check_ins   = @location.check_ins.this_month.count

    counts     = @location.check_ins.group(:user_id).count
    last_times = @location.check_ins.group(:user_id).maximum(:created_at)
    user_ids   = counts.keys.compact
    users      = User.where(id: user_ids).index_by(&:id)

    @user_stats = counts.map do |uid, count|
      if uid
        { user: users[uid], count: count, last_at: last_times[uid] }
      else
        { user: nil, guest: true, count: count, last_at: last_times[uid] }
      end
    end.sort_by { |s| -s[:count] }

    @recent_check_ins = @location.check_ins.ordered.includes(:user).limit(20)
  end

  def new
    @location = Location.new
    @location.build_address
    authorize(@location)
  end

  def edit
    @location.build_address unless @location.address
  end

  def create
    @location = Location.new(location_params)
    authorize(@location)

    if @location.save
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      )
      SyncLocationCalendarJob.perform_later(@location.id, Current.tenant.id) if @location.ical_url.present?
      redirect_to admin_location_path(@location), notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @location.logo.purge_later if params[:remove_logo].present?
    @location.background.purge_later if params[:remove_background].present?
    if @location.update(location_params)
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      ) unless @location.qr_code
      SyncLocationCalendarJob.perform_later(@location.id, Current.tenant.id) if @location.ical_url.present?
      redirect_to admin_location_path(@location), notice: "Location was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @location.destroy!
    redirect_to admin_locations_path, notice: "Location was successfully deleted."
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:hashid])
    authorize(@location)
  end

  def location_params
    params.require(:location).permit(:name, :published, :logo, :background, :ical_url, :message, :checkin_exit_url, :background_tint_opacity, address_attributes: [:id, :street_address, :city, :province, :postal_code, :country])
  end
end
