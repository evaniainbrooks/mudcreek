class QrCodeMailer < ApplicationMailer
  def scan_notification(qr_code)
    @qr_code  = qr_code
    @tenant   = qr_code.tenant

    mail(
      to:      qr_code.notify_user.email_address,
      subject: "QR code scanned: #{qr_code.name}"
    )
  end
end
