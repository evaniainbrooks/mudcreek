class QrCodesController < ApplicationController
  include QrImageRendering

  allow_unauthenticated_access

  def qr_image
    qr_code = QrCode.find_by!(slug: params[:slug])

    unless qr_code.live?
      head :not_found
      return
    end

    render_qr_image(qr_code)
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
