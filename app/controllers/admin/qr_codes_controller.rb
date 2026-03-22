class Admin::QrCodesController < Admin::BaseController
  before_action :set_qr_code, only: %i[show edit update destroy qr_image]

  def index
    authorize(QrCode)
    @pagy, @qr_codes = pagy(:keyset, QrCode.ordered.includes(:owner))
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
    @qr_code.owner = Current.user
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

  QR_SIZES = {
    "sm" => { png: 150, svg_module: 3 },
    "md" => { png: 300, svg_module: 6 },
    "lg" => { png: 600, svg_module: 10 }
  }.freeze

  QR_STYLES = {
    "standard" => { svg_color: "000000", png_color: "#000000", png_fill: "white" },
    "blue"      => { svg_color: "0d6efd", png_color: "#0d6efd", png_fill: "white" },
    "indigo"    => { svg_color: "6610f2", png_color: "#6610f2", png_fill: "white" },
    "purple"    => { svg_color: "6f42c1", png_color: "#6f42c1", png_fill: "white" },
    "pink"      => { svg_color: "d63384", png_color: "#d63384", png_fill: "white" },
    "red"       => { svg_color: "dc3545", png_color: "#dc3545", png_fill: "white" },
    "orange"    => { svg_color: "fd7e14", png_color: "#fd7e14", png_fill: "white" },
    "green"     => { svg_color: "198754", png_color: "#198754", png_fill: "white" },
    "teal"      => { svg_color: "20c997", png_color: "#20c997", png_fill: "white" },
  }.freeze

  def qr_image
    size_key  = QR_SIZES.key?(params[:size])  ? params[:size]  : "md"
    style_key = QR_STYLES.key?(params[:style]) ? params[:style] : "standard"
    size      = QR_SIZES[size_key]
    style     = QR_STYLES[style_key]
    qr        = ::RQRCode::QRCode.new(qr_redirect_url(@qr_code.slug))

    respond_to do |format|
      format.svg do
        svg = qr.as_svg(offset: 0, color: style[:svg_color], shape_rendering: "crispEdges",
                        module_size: size[:svg_module])
        disposition = params[:download] ? "attachment" : "inline"
        send_data svg, type: "image/svg+xml", disposition: disposition,
                       filename: "#{@qr_code.slug}-#{size_key}.svg"
      end
      format.png do
        png = qr.as_png(size: size[:png], color: style[:png_color], fill: style[:png_fill])
        send_data png.to_s, type: "image/png", disposition: "attachment",
                            filename: "#{@qr_code.slug}-#{size_key}.png"
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
