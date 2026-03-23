module QrImageRendering
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
    "teal"      => { svg_color: "20c997", png_color: "#20c997", png_fill: "white" }
  }.freeze

  private

  def render_qr_image(qr_code)
    size_key  = QR_SIZES.key?(params[:size])  ? params[:size]  : "md"
    style_key = QR_STYLES.key?(params[:style]) ? params[:style] : "standard"
    size      = QR_SIZES[size_key]
    style     = QR_STYLES[style_key]
    qr        = ::RQRCode::QRCode.new(qr_redirect_url(qr_code.slug))

    respond_to do |format|
      format.svg do
        svg = qr.as_svg(offset: 0, color: style[:svg_color], shape_rendering: "crispEdges",
                        module_size: size[:svg_module])
        disposition = params[:download] ? "attachment" : "inline"
        send_data svg, type: "image/svg+xml", disposition: disposition,
                       filename: "#{qr_code.slug}-#{size_key}.svg"
      end
      format.png do
        png = qr.as_png(size: size[:png], color: style[:png_color], fill: style[:png_fill])
        send_data png.to_s, type: "image/png", disposition: "attachment",
                            filename: "#{qr_code.slug}-#{size_key}.png"
      end
    end
  end
end
