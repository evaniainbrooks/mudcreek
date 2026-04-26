class CheckIn < ApplicationRecord
  include MultiTenant

  belongs_to :user, optional: true
  belongs_to :location
  belongs_to :schedule_event, optional: true
  belongs_to :schedule_event_registration, optional: true

  validates :guest_name, presence: true, if: -> { user_id.nil? }

  scope :today,      -> { where(created_at: current_tenant_time.beginning_of_day..) }
  scope :this_week,  -> { where(created_at: current_tenant_time.beginning_of_week..) }
  scope :this_month, -> { where(created_at: current_tenant_time.beginning_of_month..) }

  def self.current_tenant_time = Time.current.in_time_zone(Current.tenant.timezone)
  scope :ordered,    -> { order(created_at: :desc) }
end
