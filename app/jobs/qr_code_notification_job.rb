class QrCodeNotificationJob < ApplicationJob
  def perform(qr_code_id)
    qr_code = QrCode.unscoped.find_by(id: qr_code_id)
    return unless qr_code&.notify_user

    debounce = qr_code.notification_debounce_seconds
    return if qr_code.last_scanned_at > debounce.seconds.ago

    QrCodeMailer.scan_notification(qr_code).deliver_now
  end
end
