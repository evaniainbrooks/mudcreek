class Admin::QrCodesController < Admin::BaseController
  include QrImageRendering

  before_action :set_qr_code, only: %i[show edit update destroy qr_image]

  def index
    authorize(QrCode)
    @pagy, @qr_codes = pagy(:keyset, QrCode.ordered.includes(:owner))
  end

  def show
    @recent_scans     = @qr_code.qr_scans.order(created_at: :desc).limit(20)
    @users            = User.order(:first_name, :last_name)
    @location_qr_code = @qr_code.location_qr_code?
  end

  def new
    @qr_code = QrCode.new
    authorize(@qr_code)
    @users = User.order(:first_name, :last_name)
  end

  def edit
    @users = User.order(:first_name, :last_name)
    @location_qr_code = @qr_code.location_qr_code?
  end

  def create
    @qr_code = QrCode.new(qr_code_params)
    @qr_code.owner = Current.user
    authorize(@qr_code)

    if @qr_code.save
      redirect_to admin_qr_codes_path, notice: t(".notice")
    else
      @users = User.order(:first_name, :last_name)
      render :new, status: :unprocessable_content
    end
  end

  def update
    permitted = @qr_code.location_qr_code? ? location_qr_code_params : qr_code_params
    if @qr_code.update(permitted)
      redirect_to admin_qr_codes_path, notice: t(".notice")
    else
      @location_qr_code = @qr_code.location_qr_code?
      @users = User.order(:first_name, :last_name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @qr_code.location_qr_code?
      redirect_to admin_qr_codes_path, alert: t(".alert")
      return
    end
    @qr_code.destroy!
    redirect_to admin_qr_codes_path, notice: t(".notice")
  end

  def qr_image
    render_qr_image(@qr_code)
  end

  private

  def set_qr_code
    @qr_code = QrCode.find_by!(slug: params[:slug])
    authorize(@qr_code)
  end

  def qr_code_params
    params.require(:qr_code).permit(:name, :slug, :destination_url, :inactive_url, :notes, :active, :expires_at, :notify_user_id, :notification_debounce_seconds)
  end

  def location_qr_code_params
    params.require(:qr_code).permit(:notes, :notify_user_id, :notification_debounce_seconds)
  end
end
