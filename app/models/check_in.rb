class CheckIn < ApplicationRecord
  include MultiTenant
  include NativeEnum

  belongs_to :user, optional: true
  belongs_to :location
  belongs_to :schedule_event, optional: true
  belongs_to :schedule_event_registration, optional: true

  native_enum :source, %i[kiosk schedule admin], default: "kiosk"

  validates :guest_name, presence: true, if: -> { user_id.nil? }
  validates :schedule_event_registration_id, uniqueness: true, allow_nil: true

  scope :today,      -> { where(created_at: current_tenant_time.beginning_of_day..) }
  scope :this_week,  -> { where(created_at: current_tenant_time.beginning_of_week..) }
  scope :this_month, -> { where(created_at: current_tenant_time.beginning_of_month..) }

  def self.current_tenant_time = Time.current.in_time_zone(Current.tenant.timezone)
  scope :ordered,    -> { order(created_at: :desc) }
end
