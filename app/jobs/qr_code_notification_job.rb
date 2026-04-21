class QrCodeNotificationJob < ApplicationJob
  def perform(qr_code_id)
    qr_code = QrCode.unscoped.find_by(id: qr_code_id)
    return unless qr_code&.notify_user

    debounce = qr_code.notification_debounce_seconds
    return if qr_code.last_scanned_at > debounce.seconds.ago

    window_start = qr_code.last_notified_at
    scans = qr_code.qr_scans.order(:created_at)
    scans = scans.where("created_at > ?", window_start) if window_start

    qr_code.update_columns(last_notified_at: Time.current)
    QrCodeMailer.scan_notification(qr_code, scans).deliver_now
  end
end
