class ScheduleEventSession < ApplicationRecord
  include MultiTenant

  belongs_to :schedule_event
  has_many :schedule_event_registrations, dependent: :destroy

  validates :occurs_on, presence: true
  validates :schedule_event_id, uniqueness: { scope: :occurs_on }

  def confirmed_registrations
    schedule_event_registrations.confirmed
  end
end
