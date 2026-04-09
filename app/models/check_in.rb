class CheckIn < ApplicationRecord
  include MultiTenant

  belongs_to :user, optional: true
  belongs_to :location

  validates :guest_name, presence: true, if: -> { user_id.nil? }

  scope :today,      -> { where(created_at: current_tenant_time.beginning_of_day..) }
  scope :this_week,  -> { where(created_at: current_tenant_time.beginning_of_week..) }
  scope :this_month, -> { where(created_at: current_tenant_time.beginning_of_month..) }

  def self.current_tenant_time
    tz = Current.tenant&.timezone.presence
    tz ? Time.current.in_time_zone(tz) : Time.current
  end
  scope :ordered,    -> { order(created_at: :desc) }
end
