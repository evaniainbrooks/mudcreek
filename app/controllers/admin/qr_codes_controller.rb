class Admin::QrCodesController < Admin::BaseController
  before_action :set_qr_code, only: %i[show edit update destroy qr_image]

  def index
    authorize(QrCode)
    @qr_codes = QrCode.ordered
  end

  def show
    @recent_scans = @qr_code.qr_scans.order(created_at: :desc).limit(20)
  end

  def new
    @qr_code = QrCode.new
    authorize(@qr_code)
  end

  def edit
  end

  def create
    @qr_code = QrCode.new(qr_code_params)
    authorize(@qr_code)

    if @qr_code.save
      redirect_to admin_qr_codes_path, notice: "QR code was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @qr_code.update(qr_code_params)
      redirect_to admin_qr_codes_path, notice: "QR code was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @qr_code.destroy!
    redirect_to admin_qr_codes_path, notice: "QR code was successfully deleted."
  end

  def qr_image
    qr = RQRCode::QRCode.new(qr_redirect_url(@qr_code.slug))

    respond_to do |format|
      format.svg do
        svg = qr.as_svg(offset: 0, color: "000", shape_rendering: "crispEdges", module_size: 4)
        send_data svg, type: "image/svg+xml", disposition: "inline"
      end
      format.png do
        png = qr.as_png(size: 300)
        send_data png.to_s, type: "image/png", disposition: "attachment",
                            filename: "#{@qr_code.slug}.png"
      end
    end
  end

  private

  def set_qr_code
    @qr_code = QrCode.find_by!(slug: params[:slug])
    authorize(@qr_code)
  end

  def qr_code_params
    params.require(:qr_code).permit(:name, :slug, :destination_url, :inactive_url, :notes, :active, :expires_at)
  end
end
