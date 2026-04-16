class QrRedirectsController < ApplicationController
  allow_unauthenticated_access

  def show
    qr_code = QrCode.find_by!(slug: params[:slug])

    if qr_code.live?
      qr_code.record_scan!(request) unless bot_request?
      redirect_to qr_code.destination_url, allow_other_host: true, status: :found
    else
      redirect_to qr_code.fallback_url || root_path, allow_other_host: true, status: :found
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, status: :found
  end
end
