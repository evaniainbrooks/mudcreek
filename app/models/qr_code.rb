class QrCode < ApplicationRecord
  include MultiTenant

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :notify_user, class_name: "User", optional: true
  belongs_to :location, optional: true
  has_many :qr_scans, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" },
    uniqueness: { scope: :tenant_id }
  validates :destination_url, presence: true
  validates :location_id, uniqueness: true, allow_nil: true

  before_validation :derive_slug, on: :create, if: -> { slug.blank? && name.present? }

  scope :ordered, -> { order(:name) }

  def to_param = slug

  def location_qr_code? = location_id.present?

  def live?
    active? && (expires_at.nil? || expires_at.future?)
  end

  def fallback_url
    inactive_url.presence
  end

  def record_scan!(request)
    QrCode.unscoped.where(id: id)
          .update_all("scan_count = scan_count + 1, last_scanned_at = NOW()")
    qr_scans.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    QrCodeNotificationJob.set(wait: notification_debounce_seconds.seconds).perform_later(id) if notify_user
  end

  private

  def derive_slug
    self.slug = name.parameterize
  end
end
