class Admin::LocationsController < Admin::BaseController
  before_action :set_location, only: %i[show edit update destroy]

  def index
    authorize(Location)
    @pagy, @locations = pagy(:keyset, Location.ordered)
  end

  def show
    @qr_code = @location.qr_code
    load_check_in_stats
    @location.build_address unless @location.address
    @kiosk           = @location.kiosk || @location.build_kiosk
    @members         = @location.users.active.order(:first_name, :last_name)
    @non_members     = User.active.where.not(id: @members.select(:id)).order(:first_name, :last_name)
    @announcements   = @location.location_announcements.ordered.limit(5)
    @schedules       = @location.schedules.ordered
    @drop_in_listings = Listing.not_in_auction.where(published: true, state: :on_sale).order(:name)
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

    if @location.save
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      )
      redirect_to admin_location_path(@location), notice: t(".notice")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @location.update(location_params)
      @location.create_qr_code!(
        name:            "#{@location.name} Check-in",
        destination_url: location_checkin_url(@location, tenant_key: Current.tenant.key),
        active:          true,
        owner:           Current.user
      ) unless @location.qr_code
      redirect_to admin_location_path(@location), notice: t(".notice")
    else
      @qr_code = @location.qr_code
      load_check_in_stats
      @location.build_address unless @location.address
      @kiosk            = @location.kiosk || @location.build_kiosk
      @members          = @location.users.active.order(:first_name, :last_name)
      @non_members      = User.active.where.not(id: @members.select(:id)).order(:first_name, :last_name)
      @announcements    = @location.location_announcements.ordered.limit(5)
      @schedules        = @location.schedules.ordered
      @drop_in_listings = Listing.not_in_auction.where(published: true, state: :on_sale).order(:name)
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    @location.destroy!
    redirect_to admin_locations_path, notice: t(".notice")
  end

  private

  def set_location
    @location = Location.find_by!(hashid: params[:hashid])
    authorize(@location)
  end

  def load_check_in_stats
    @total_check_ins = @location.check_ins.count
    @today_check_ins = @location.check_ins.today.count
    @week_check_ins  = @location.check_ins.this_week.count
    @month_check_ins = @location.check_ins.this_month.count

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

    @user_stats       = (user_rows + guest_rows).sort_by { |s| -s[:count] }.first(20)
    @recent_check_ins = @location.check_ins.ordered.includes(:user, :schedule_event).limit(20)
  end

  def location_params
    params.require(:location).permit(:name, :published, :default, :directions, :tax_rate_percent, address_attributes: [:id, :street_address, :city, :province, :postal_code, :country])
  end
end
