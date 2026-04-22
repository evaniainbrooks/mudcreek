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

    user_counts     = @location.check_ins.where.not(user_id: nil).group(:user_id).count
    user_last_times = @location.check_ins.where.not(user_id: nil).group(:user_id).maximum(:created_at)
    users           = User.where(id: user_counts.keys).index_by(&:id)

    guest_counts     = @location.check_ins.where(user_id: nil).group(:guest_name).count
    guest_last_times = @location.check_ins.where(user_id: nil).group(:guest_name).maximum(:created_at)

    user_rows = user_counts.map do |uid, count|
      { user: users[uid], count: count, last_at: user_last_times[uid] }
    end

    guest_rows = guest_counts.map do |name, count|
      { guest_name: name, count: count, last_at: guest_last_times[name] }
    end

    @user_stats = (user_rows + guest_rows).sort_by { |s| -s[:count] }.first(20)

    @recent_check_ins = @location.check_ins.ordered.includes(:user).limit(20)

    @location.build_address unless @location.address
    @members       = @location.users.order(:first_name, :last_name)
    @non_members   = User.where.not(id: @members.select(:id)).order(:first_name, :last_name)
    @announcements = @location.location_announcements.ordered.limit(5)
    @schedules     = @location.schedules.ordered
  end

  def new
    @location = Location.new
    @location.build_address
    authorize(@location)
  end

  def edit
    redirect_to admin_location_path(@location)
  end

  def create
    @location = Location.new(location_params)
    authorize(@location)

    new_backgrounds = params.dig(:location, :backgrounds)&.reject(&:blank?)
    if @location.save
      @location.backgrounds.attach(new_backgrounds) if new_backgrounds.present?
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      )
      redirect_to admin_location_path(@location), notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @location.logo.purge_later if params[:remove_logo].present?
    Array(params[:remove_background_ids]).each do |signed_id|
      blob = ActiveStorage::Blob.find_signed(signed_id)
      @location.backgrounds.attachments.find_by(blob_id: blob.id)&.purge_later
    end
    new_backgrounds = params.dig(:location, :backgrounds)&.reject(&:blank?)
    if @location.update(location_params)
      @location.backgrounds.attach(new_backgrounds) if new_backgrounds.present?
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      ) unless @location.qr_code
      redirect_to admin_location_path(@location), notice: "Location was successfully updated."
    else
      @location.build_address unless @location.address
      @qr_code      = @location.qr_code
      @members      = @location.users.order(:first_name, :last_name)
      @non_members  = User.where.not(id: @members.select(:id)).order(:first_name, :last_name)
      @announcements = @location.location_announcements.ordered.limit(5)
      @schedules    = @location.schedules.ordered
      render :show, status: :unprocessable_content
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
    params.require(:location).permit(:name, :published, :default, :logo, :message, :directions, :checkin_exit_url, :background_tint_opacity, :slide_timeout, :tax_rate_percent, address_attributes: [:id, :street_address, :city, :province, :postal_code, :country])
  end
end
